#!/usr/bin/env python3
"""Replace raw debugPrint calls with AppLogger.d across the Dart codebase."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
TEST = ROOT / "test"

APP_LOGGER_IMPORT = "import 'package:gruve_app/core/utils/app_logger.dart';"

SKIP_FILES = {
    LIB / "core" / "utils" / "app_logger.dart",
}


def add_import(content: str) -> str:
    if APP_LOGGER_IMPORT in content:
        return content

    lines = content.splitlines(keepends=True)
    insert_at = 0
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("import ") or stripped.startswith("export "):
            insert_at = i + 1
        elif stripped and not stripped.startswith("//") and insert_at > 0:
            break

    lines.insert(insert_at, APP_LOGGER_IMPORT + "\n")
    return "".join(lines)


def strip_redundant_kdebug_guards(content: str) -> str:
    # if (kDebugMode) AppLogger.d(...);
    content = re.sub(
        r"if\s*\(\s*kDebugMode\s*\)\s*(AppLogger\.\w+\([^;]*;)",
        r"\1",
        content,
        flags=re.MULTILINE,
    )

    # if (kDebugMode) { AppLogger.x(...); }  (single statement block)
    content = re.sub(
        r"if\s*\(\s*kDebugMode\s*\)\s*\{\s*(AppLogger\.\w+\([\s\S]*?\);\s*)\}",
        r"\1",
        content,
    )

    return content


def process_file(path: Path) -> bool:
    if path in SKIP_FILES:
        return False

    original = path.read_text(encoding="utf-8")
    content = original

    # Never touch the global debugPrint override assignment in main.dart.
    content = re.sub(r"\bdebugPrint\(", "AppLogger.d(", content)

    if "AppLogger." not in content:
        return False

    content = strip_redundant_kdebug_guards(content)

    if APP_LOGGER_IMPORT not in content:
        content = add_import(content)

    if content == original:
        return False

    path.write_text(content, encoding="utf-8")
    return True


def main() -> None:
    changed = 0
    targets = list(LIB.rglob("*.dart"))
    if TEST.exists():
        targets.extend(TEST.rglob("*.dart"))

    for path in sorted(targets):
        if process_file(path):
            changed += 1
            print(f"updated: {path.relative_to(ROOT)}")

    print(f"\nDone. Updated {changed} files.")


if __name__ == "__main__":
    main()
