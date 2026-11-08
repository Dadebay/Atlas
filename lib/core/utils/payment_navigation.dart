bool isSecureWebUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;
}

bool isPaymentReturnUrl(String rawUrl, Iterable<String> allowedHosts) {
  final uri = Uri.tryParse(rawUrl);
  return uri != null &&
      isSecureWebUrl(rawUrl) &&
      allowedHosts.any((host) => uri.host == host);
}
