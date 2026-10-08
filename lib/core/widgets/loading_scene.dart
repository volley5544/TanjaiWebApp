import 'package:flutter/material.dart';

/// Full-screen loading overlay — port of FF `LoadingSceneWidget`: 50% black
/// scrim, spinning ring (120×120) with the Tanjai logo GIF (50×50) centred.
class LoadingScene extends StatelessWidget {
  const LoadingScene({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0x80000000),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/images/loading_spin.gif', width: 120, height: 120, fit: BoxFit.scaleDown),
          Image.asset('assets/images/loading_logo.gif', width: 50, height: 50, fit: BoxFit.cover),
        ],
      ),
    );
  }
}

/// Shows [LoadingScene] over the whole app while [task] runs, and **always**
/// removes it afterwards — including when [task] throws or returns early. (The
/// FF pages showed it as a bottom sheet and on several error paths never
/// popped it, leaving the user stuck behind the overlay.)
///
/// Uses an [OverlayEntry] instead of a route so it can't be popped by the
/// browser back button and doesn't interfere with `Navigator.pop` results.
Future<T> withLoading<T>(BuildContext context, Future<T> Function() task) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (_) => const Material(type: MaterialType.transparency, child: LoadingScene()),
  );
  overlay.insert(entry);
  try {
    return await task();
  } finally {
    entry.remove();
  }
}
