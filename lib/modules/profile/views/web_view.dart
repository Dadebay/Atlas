import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/themes/colors.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:atlas/core/utils/app_log.dart';

class InfoWebViewPage extends StatefulWidget {
  const InfoWebViewPage({
    super.key,
    required this.url,
    required this.title,
    this.autoCloseHosts = const [],
  });

  final String url;
  final String title;

  // Bu host'lardan birine redirect gelince WebView otomatik kapanır
  final List<String> autoCloseHosts;

  @override
  State<InfoWebViewPage> createState() => _InfoWebViewPageState();
}

class _InfoWebViewPageState extends State<InfoWebViewPage> {
  InAppWebViewController? _webViewController;

  bool _isAutoCloseUrl(String url) {
    if (widget.autoCloseHosts.isEmpty) return false;
    return widget.autoCloseHosts.any((host) => url.contains(host));
  }

  Future<ServerTrustAuthResponse> _onReceivedServerTrustAuthRequest(
      InAppWebViewController controller,
      URLAuthenticationChallenge challenge) async {
    return ServerTrustAuthResponse(
        action: ServerTrustAuthResponseAction.PROCEED);
  }

  FutureOr<bool> _launchURL(String uri) async {
    try {
      String newUri = uri;
      if (uri.startsWith('intent')) {
        newUri = uri.replaceFirst('intent', 'https');
      }
      await launchUrlString(newUri, mode: LaunchMode.externalApplication);
    } catch (e, s) {
      AppLog.e('InfoWebViewPage.launchUrl', e, s);
    }
    return false;
  }

  Future<NavigationActionPolicy> _shouldOverrideUrlLoading(
      InAppWebViewController controller,
      NavigationAction navigationAction) async {
    final uri = navigationAction.request.url;
    if (uri == null) return NavigationActionPolicy.CANCEL;

    final uriString = uri.toString();
    AppLog.d('[WebView] ► navigating: $uriString');

    // Ödeme return URL'i — WebView'ı kapat
    if (_isAutoCloseUrl(uriString)) {
      AppLog.d('[WebView] ✓ ödeme return URL algılandı, kapanıyor');
      Get.back();
      return NavigationActionPolicy.CANCEL;
    }

    if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
      return NavigationActionPolicy.ALLOW;
    } else {
      _launchURL(uriString);
      return NavigationActionPolicy.CANCEL;
    }
  }

  Future<bool> _onCreateWindow(
      InAppWebViewController controller, CreateWindowAction action) async {
    final uri = action.request.url;
    if (uri == null) return false;

    final uriString = uri.toString();
    if (_isAutoCloseUrl(uriString)) {
      AppLog.d('[WebView] ✓ ödeme return URL (yeni pencere), kapanıyor');
      Get.back();
      return false;
    }

    if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
      return true;
    } else {
      _launchURL(uriString);
      return false;
    }
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) {
    if (url == null) return;
    final uriString = url.toString();
    if (_isAutoCloseUrl(uriString)) {
      AppLog.d('[WebView] ✓ ödeme return URL (onLoadStop), kapanıyor');
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 24,
            color: AppColors.green,
          ),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF1D1B20),
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: 'Gilroy',
          ),
        ),
      ),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          onWebViewCreated: (c) => _webViewController = c,
          onCreateWindow: _onCreateWindow,
          shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
          onReceivedServerTrustAuthRequest: _onReceivedServerTrustAuthRequest,
          onLoadStop: _onLoadStop,
          initialSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: true,
            javaScriptEnabled: true,
            useHybridComposition: true,
            allowsInlineMediaPlayback: true,
          ),
        ),
      ),
    );
  }
}
