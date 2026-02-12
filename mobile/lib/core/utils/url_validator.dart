class UrlValidator {
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a URL';
    }

    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);

    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Please enter a valid URL (e.g. https://example.com/recipe)';
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'URL must start with http:// or https://';
    }

    if (uri.host.isEmpty || !uri.host.contains('.')) {
      return 'Please enter a valid URL (e.g. https://example.com/recipe)';
    }

    return null;
  }

  static bool isValid(String? value) => validate(value) == null;
}
