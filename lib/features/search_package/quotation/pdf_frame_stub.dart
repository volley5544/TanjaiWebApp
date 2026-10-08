import 'package:flutter/widgets.dart';

/// Non-web stand-in: nothing to embed.
class PdfFrame extends StatelessWidget {
  const PdfFrame({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void openUrlInNewTab(String url) {}
