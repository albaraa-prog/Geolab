// Web-specific implementation for cleaning URL hash fragments
import 'dart:html' as html;

/// Get the current URL href (web only)
String getCurrentUrlHref() {
  return html.window.location.href;
}

void cleanResetPasswordUrl() {
  try {
    // Get current URL
    final currentHref = html.window.location.href;
    
    // Check if URL has hash fragment and is on reset-password with code
    if (currentHref.contains('#') && 
        currentHref.contains('/reset-password') && 
        currentHref.contains('code=')) {
      
      // Parse the URL
      final uri = Uri.parse(currentHref);
      
      // Extract just the path and query (without hash)
      final cleanPath = uri.path;
      final cleanQuery = uri.query;
      
      // Build clean URL without hash fragment
      var cleanUrl = '${uri.scheme}://${uri.host}';
      if (uri.port != 80 && uri.port != 443) {
        cleanUrl += ':${uri.port}';
      }
      cleanUrl += cleanPath;
      if (cleanQuery.isNotEmpty) {
        cleanUrl += '?$cleanQuery';
      }
      
      // Multiple aggressive attempts to clear the hash
      // Method 1: Clear hash directly
      html.window.location.hash = '';
      
      // Method 2: Use replaceState
      html.window.history.replaceState(null, '', cleanUrl);
      
      // Method 3: Clear hash again
      html.window.location.hash = '';
      
      // Method 4: Use location.replace if hash persists
      if (html.window.location.hash.isNotEmpty) {
        html.window.location.replace(cleanUrl);
      }
      
      // Method 5: Final check and clear after a microtask
      // This ensures we catch any async hash additions
      Future.microtask(() {
        if (html.window.location.hash.isNotEmpty) {
          html.window.location.hash = '';
          html.window.history.replaceState(null, '', cleanUrl);
        }
      });
    }
  } catch (e) {
    // Ignore errors in URL cleaning

  }
}

