import 'package:flutter/material.dart';

import 'business_logo_stub.dart'
    if (dart.library.io) 'business_logo_io.dart' as platform;

Widget buildBusinessLogo(String path, {double size = 36}) {
  return platform.buildBusinessLogo(path, size: size);
}