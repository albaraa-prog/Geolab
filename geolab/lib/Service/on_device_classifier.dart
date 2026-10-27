/// Offline rock classification with the distilled TFLite model.
///
/// Uses the real implementation where dart:ffi exists (Android, iOS,
/// desktop) and a stub on the web, where TFLite is not available.
export 'on_device_classifier_stub.dart'
    if (dart.library.ffi) 'on_device_classifier_io.dart';
