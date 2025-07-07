// A WebView widget for displaying external URLs inside the app.
// Includes progress tracking, error handling, and dark mode support.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A screen that loads and displays a web page inside a WebView.
/// Shows a progress indicator while loading, a "Done" button to exit,
/// and an error message if the page fails to load.
class UrlLauncherWebView extends StatefulWidget {
  final String url;
  final String title;
  const UrlLauncherWebView({super.key, required this.url, required this.title});

  @override
  State<UrlLauncherWebView> createState() => _UrlLauncherWebViewState();
}

class _UrlLauncherWebViewState extends State<UrlLauncherWebView> {
  var loadingPercentage = 0;
  late final WebViewController webViewController;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    // Initialize the WebView controller and configure its behavior.
    webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              // Update loading progress percentage.
              onProgress: (int progress) {
                setState(() {
                  loadingPercentage = progress;
                });
              },
              // Reset loading progress to 0 when page starts.
              onPageStarted: (String url) {
                loadingPercentage = 0;
              },
              // Set loading to complete when page finishes.
              onPageFinished: (String url) {
                setState(() {
                  loadingPercentage = 100;
                });
              },
              // Show error state on HTTP errors.
              onHttpError: (HttpResponseError error) {
                setState(() {
                  hasError = true;
                });
              },
              // Show error state on resource loading errors.
              onWebResourceError: (WebResourceError error) {
                setState(() {
                  hasError = true;
                });
              },
              // Prevent navigation to YouTube links.
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith('https://www.youtube.com/')) {
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Main layout: includes AppBar and conditional WebView or error screen.
    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor:
            darkMode
                ? const Color.fromARGB(255, 0, 0, 0)
                : const Color.fromARGB(255, 255, 255, 255),
        // Display the web page title.
        leading: Padding(
          padding: EdgeInsets.only(top: height * 0.017, left: width * 0.02),
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        leadingWidth: width / 1.5,
        // Provide a "Done" button to close the web view.
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Done',
              style: TextStyle(
                fontSize: width * 0.038,
                color: const Color.fromARGB(255, 33, 150, 243),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      // Show error message if loading fails, otherwise display WebView with loading bar.
      body:
          hasError
              ? Center(
                child: Text(
                  'Unable to load page.\nPlease check your connection or try again later.',
                  style: TextStyle(
                    color: darkMode ? Colors.white : Colors.black,
                    fontSize: width * 0.045,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              : Stack(
                children: [
                  WebViewWidget(
                    controller: webViewController,
                    // Enable gestures inside the WebView.
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
                  // Show a linear progress bar while the page is loading.
                  loadingPercentage < 100
                      ? LinearProgressIndicator(
                        value: loadingPercentage / 100,
                        color: const Color.fromARGB(255, 33, 150, 243),
                        backgroundColor: Colors.transparent,
                      )
                      : const SizedBox.shrink(),
                ],
              ),
    );
  }
}
