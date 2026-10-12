// Picks the right platform implementation at compile time: dart:html on
// Flutter Web, dart:io + share sheet everywhere else. Neither concrete
// implementation is ever imported directly outside this file, so callers
// stay platform-agnostic.
export 'report_file_saver_io.dart' if (dart.library.html) 'report_file_saver_web.dart';