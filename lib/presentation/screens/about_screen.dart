import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:quiz/presentation/widgets/app_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  final String github = 'https://github.com/Ayush-K-Garg';
  final String linkedin = 'https://www.linkedin.com/in/ayush-krishna-garg-7aa61a28a/';

  Future<void> _launchSmart(BuildContext context, String url) async {
    try {
      debugPrint("🔗 Trying to launch: $url");

      bool success = await launch(url); // legacy launch
      debugPrint("✅ launch() result: $success");

      if (!success) {
        _openInWebView(context, url);
      }
    } catch (e) {
      debugPrint("🚨 Exception in launch: $e");
      _openInWebView(context, url);
    }
  }

  void _openInWebView(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WebViewScreen(url: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text("About TrivIQ"),
        backgroundColor: const Color(0xFF2C2C54),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset('assets/images/applogo.png', height: 100),
                  const SizedBox(height: 12),
                  const Text(
                    "TriviQ",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("Features", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const FeatureItem(text: "Real-time multiplayer matchups"),
            const FeatureItem(text: "Single Player Practice Mode"),
            const FeatureItem(text: "Leaderboard and scoring"),
            const SizedBox(height: 24),
            const Text("Developer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Ayush Krishna Garg", style: TextStyle(fontSize: 16)),
            const Text("ECE, NIT JSR'27", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: Image.asset('assets/icons/github.png', height: 28),
                  tooltip: 'GitHub',
                  onPressed: () => _launchSmart(context, github),
                ),
                IconButton(
                  icon: Image.asset('assets/icons/linkedin.png', height: 28),
                  tooltip: 'LinkedIn',
                  onPressed: () => _launchSmart(context, linkedin),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Last updated: June 2025", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Divider(),
          ],
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final String text;
  const FeatureItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
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
    final params = const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("In-App Browser")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
