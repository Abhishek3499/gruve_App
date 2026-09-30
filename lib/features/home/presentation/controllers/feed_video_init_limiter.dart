import 'dart:async';

/// Caps concurrent feed video initializations — Exynos/Snapdragon decoders
/// exhaust quickly when multiple HEVC clips init during fast scroll. Exactly
/// one native `initialize()` call is ever in flight at a time, for CURRENT
/// and preload alike — CURRENT gets priority only in the sense that it jumps
/// ahead of any queued preload waiter for the next free slot; it can never
/// preempt whatever is already running, since interrupting a live native
/// initialize() is not safe (see the cancel-function history elsewhere in
/// this file).
///
/// Priority is tracked per-waiter as a LIVE callback (`isPriority`), not a
/// snapshot taken when the waiter joined the queue. This matters for the
/// "in-flight reuse" path in `_ensureCurrentVideoReady`: a video that started
/// initializing as a PRELOAD can become the live CURRENT video while its
/// attempt is still queued (or still running natively) — the caller simply
/// awaits that same attempt rather than starting a second one. Without a
/// live re-check, that promoted attempt would keep the low-priority,
/// 6-second-timeout treatment it queued under, letting an ordinary preload
/// occupy the single slot while the video the user is actually looking at
/// sits waiting behind it. Re-evaluating `isPriority` on every pick lets a
/// promoted attempt jump straight to the front — matching a CURRENT request
/// that was CURRENT from the very start — while a demoted one (current moved
/// on again before this attempt reached the slot) falls back to ordinary
/// preload treatment on its very next wake.
class FeedVideoInitLimiter {
  static const int _maxConcurrent = 1;
  static int _active = 0;
  static int _epoch = 0;
  static final List<_LimiterWaiter> _waitQueue = <_LimiterWaiter>[];

  static int get epoch => _epoch;

  static void bumpEpoch() {
    _epoch++;
    final waiters = List<_LimiterWaiter>.from(_waitQueue);
    _waitQueue.clear();
    for (final waiter in waiters) {
      if (!waiter.completer.isCompleted) {
        waiter.completer.complete();
      }
    }
  }

  /// Runs [task] once a slot is free and [isValid] still says so.
  ///
  /// [isPriority] is polled live (at entry, right after acquiring the slot,
  /// and on every queue pick) rather than captured once — see the class doc
  /// for why that matters for a preload promoted to CURRENT mid-flight.
  ///
  /// Returns whether [task] actually ran — deliberately NOT derived from
  /// awaiting [task] itself: `task` returns `Future<void>`, and awaiting a
  /// `Future<void>` always yields `null`, so a caller checking "result ==
  /// null" to detect cancellation would (incorrectly) treat every successful
  /// run as cancelled too.
  static Future<bool> run({
    required int epoch,
    required Future<void> Function() task,
    required bool Function() isValid,
    required bool Function() isPriority,
  }) async {
    // CURRENT (priority) requests are immune to epoch-based rejection: a
    // bump means some unrelated attempt was cancelled elsewhere — possibly
    // by the very call that's keeping THIS url as current — not that this
    // attempt itself is stale. `isValid` (token/generation/current-index) is
    // the sole authority for whether a priority request is still wanted.
    bool epochOk() => isPriority() || epoch == _epoch;

    if (!isValid() || !epochOk()) return false;

    final acquired = await _acquire(epoch, isPriority);
    if (!acquired) return false;

    try {
      if (!isValid() || !epochOk()) return false;
      await task();
      return true;
    } finally {
      _release();
    }
  }

  static Future<bool> _acquire(int epoch, bool Function() isPriority) async {
    while (true) {
      if (_active < _maxConcurrent) {
        _active++;
        return true;
      }

      final waiter = _LimiterWaiter(isPriority);
      _waitQueue.add(waiter);

      if (isPriority()) {
        // No fixed wait cap: CURRENT must actually get the slot, not give up
        // early. A wake here may come from a genuine `_release()` handoff
        // (slot now free) or from `bumpEpoch()` draining the queue for an
        // unrelated cancellation elsewhere (slot still held) — loop back and
        // re-check `_active` (and re-evaluate `isPriority()` fresh, in case
        // this attempt was demoted while it waited) rather than assuming the
        // slot is ours, so two native initialize() calls can never run at
        // once.
        await waiter.completer.future;
        continue;
      }

      var timedOut = false;
      try {
        await waiter.completer.future.timeout(
          const Duration(seconds: 6),
          onTimeout: () {
            timedOut = true;
          },
        );
      } catch (_) {
        _waitQueue.remove(waiter);
        return false;
      }

      if (timedOut) {
        _waitQueue.remove(waiter);
        return false;
      }

      if (epoch != _epoch) {
        return false;
      }

      _active++;
      return true;
    }
  }

  static void _release() {
    _active--;
    if (_waitQueue.isEmpty) return;

    // Dynamic pick: any waiter whose target is CURRENTLY the live current
    // video goes first, regardless of arrival order or what it was queued
    // as — this is what lets a preload promoted to current jump ahead of
    // older, still-queued (and still merely) preload waiters. FIFO within a
    // tier since _waitQueue is insertion-ordered.
    var chosenIndex = 0;
    for (var i = 0; i < _waitQueue.length; i++) {
      if (_waitQueue[i].isPriority()) {
        chosenIndex = i;
        break;
      }
    }
    final next = _waitQueue.removeAt(chosenIndex);
    if (!next.completer.isCompleted) {
      next.completer.complete();
    }
  }
}

class _LimiterWaiter {
  _LimiterWaiter(this.isPriority);

  final bool Function() isPriority;
  final Completer<void> completer = Completer<void>();
}
