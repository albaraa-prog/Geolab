// Stub file for non-web platforms
// This file provides a stub implementation for html.window on non-web platforms

library html_stub;

class Window {
  Location get location => Location();
}

class Location {
  String get href => '';
}

final window = Window();

