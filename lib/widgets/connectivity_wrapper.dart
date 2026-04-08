import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Optimized connectivity wrapper that does NOT rebuild its child
/// on connectivity changes. Only the banner overlay reacts to
/// changes, keeping the main widget tree stable.
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final offline =
          results.contains(ConnectivityResult.none) && results.length == 1;
      if (offline != _isOffline) {
        setState(() => _isOffline = offline);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Child is never rebuilt by connectivity changes
        widget.child,
        if (_isOffline)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 10,
              child: Container(
                color: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.wifi_off_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'No internet connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
