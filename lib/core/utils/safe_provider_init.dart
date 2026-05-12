import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

/// Production-safe Provider initialization wrapper
/// Prevents "setState during build" errors by using addPostFrameCallback
class SafeProviderInit extends StatefulWidget {
  final Widget child;
  final Function(BuildContext context)? onInit;
  
  const SafeProviderInit({
    super.key,
    required this.child,
    this.onInit,
  });

  @override
  State<SafeProviderInit> createState() => _SafeProviderInitState();
}

class _SafeProviderInitState extends State<SafeProviderInit> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    
    // Schedule initialization AFTER build completes
    if (widget.onInit != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_initialized) {
          _initialized = true;
          widget.onInit!(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Extension for easy Provider initialization
extension SafeProviderContext on BuildContext {
  /// Safely fetch data in initState without causing rebuild storms
  void safeFetch<T extends ChangeNotifier>(
    Future<void> Function(T provider) fetchFunction,
  ) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = read<T>();
        fetchFunction(provider);
      }
    });
  }
}

/// Example Usage:
/// 
/// class MyScreen extends StatefulWidget {
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
/// 
/// class _MyScreenState extends State<MyScreen> {
///   @override
///   void initState() {
///     super.initState();
///     
///     // ✅ CORRECT: Use addPostFrameCallback
///     SchedulerBinding.instance.addPostFrameCallback((_) {
///       if (mounted) {
///         context.read<UserProfileProvider>().fetchProfile(userId);
///       }
///     });
///     
///     // OR use extension:
///     context.safeFetch<UserProfileProvider>(
///       (provider) => provider.fetchProfile(userId)
///     );
///   }
///   
///   @override
///   Widget build(BuildContext context) {
///     return Consumer<UserProfileProvider>(
///       builder: (context, provider, child) {
///         if (provider.isLoading) return CircularProgressIndicator();
///         if (provider.hasError) return Text('Error: ${provider.errorMessage}');
///         if (!provider.hasData) return Text('No data');
///         
///         return Text('Hello ${provider.profile!.username}');
///       },
///     );
///   }
/// }
