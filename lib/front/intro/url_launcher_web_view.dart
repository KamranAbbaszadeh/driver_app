import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                setState(() {
                  loadingPercentage = progress;
                });
              },
              onPageStarted: (String url) {
                loadingPercentage = 0;
              },
              onPageFinished: (String url) {
                setState(() {
                  loadingPercentage = 100;
                });
              },
              onHttpError: (HttpResponseError error) {
                setState(() {
                  hasError = true;
                });
              },
              onWebResourceError: (WebResourceError error) {
                setState(() {
                  hasError = true;
                });
              },
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

    return Scaffold(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor:
            darkMode
                ? const Color.fromARGB(255, 0, 0, 0)
                : const Color.fromARGB(255, 255, 255, 255),
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
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
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
