import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:roofgrid_uk/utils/constants.dart';

class CaptchaWidget extends StatefulWidget {
  final Function(String) onVerified;
  const CaptchaWidget({super.key, required this.onVerified});

  @override
  State<CaptchaWidget> createState() => _CaptchaWidgetState();
}

class _CaptchaWidgetState extends State<CaptchaWidget> {
  final _controller = WebViewController();

  @override
  void initState() {
    super.initState();
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Captcha',
        onMessageReceived: (JavaScriptMessage message) {
          print("reCAPTCHA token received: ${message.message}");
          widget.onVerified(message.message);
        },
      )
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
        <head>
          <script src="https://www.google.com/recaptcha/api.js?render=${Constants.reCaptchaSiteKey}"></script>
          <script>
            grecaptcha.ready(function() {
              grecaptcha.execute('${Constants.reCaptchaSiteKey}', {action: 'login'}).then(function(token) {
                console.log("Generated token: " + token);
                Captcha.postMessage(token);
              }).catch(function(error) {
                console.error("reCAPTCHA error: " + error);
              });
            });
          </script>
        </head>
        <body></body>
        </html>
      ''');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0, // Invisible for reCAPTCHA v3
      child: WebViewWidget(controller: _controller),
    );
  }
}
