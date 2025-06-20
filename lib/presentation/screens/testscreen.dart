import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TestLinksScreen extends StatelessWidget {
  const TestLinksScreen({super.key});

  /// Attempts to launch URL externally; falls back to WebView on failure
  Future<void> _launchSmart(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    try {
      debugPrint("🔍 Trying to launch: $url");

      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint("✅ launchUrl result: $success");

        if (!success) {
          _openInWebView(context, url);
        }
      } else {
        debugPrint("❌ canLaunchUrl returned false for: $url");
        _openInWebView(context, url);
      }
    } catch (e) {
      debugPrint("🚨 Exception while launching $url: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🚨 Error: $e")),
      );
    }
  }

  /// Opens the URL in a WebView as fallback
  void _openInWebView(BuildContext context, String url) {
    debugPrint("🌐 Opening in fallback WebView: $url");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewScreen(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Smart URL Launch")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _launchSmart('https://flutter.dev', context),
              child: const Text("Open flutter.dev"),
            ),
            ElevatedButton(
              onPressed: () => _launchSmart('https://github.com/Ayush-K-Garg', context),
              child: const Text("Open GitHub"),
            ),
            ElevatedButton(
              onPressed: () => _launchSmart('mailto:2023ugec069@gmail.com', context),
              child: const Text("Send Email"),
            ),
          ],
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final PlatformWebViewControllerCreationParams params =
    const PlatformWebViewControllerCreationParams();

    final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("In-App Browser")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
