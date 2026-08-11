class ApiConstants {
  // static const String baseUrl = 'https://216.250.9.119:4000/api';
  // static const String webBaseUrl = 'https://216.250.9.119:3000';
  // static const String fileBaseUrl = 'https://216.250.9.119:9000/public';

  static const String baseUrl = 'https://atlas.com.tm/api';
  static const String webBaseUrl = 'https://atlas.com.tm';
  static const String fileBaseUrl = 'https://atlas.com.tm/public';

  /// Safely joins [fileBaseUrl] with a relative [path].
  /// Strips leading slash from path to avoid double-slash.
  static String fileUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '$fileBaseUrl/$clean';
  }
}
