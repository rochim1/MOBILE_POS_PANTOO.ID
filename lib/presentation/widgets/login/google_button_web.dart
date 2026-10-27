import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google;

Widget googleWebButton(double width) => google.renderButton(
  configuration: google.GSIButtonConfiguration(
    theme: google.GSIButtonTheme.outline,
    size: google.GSIButtonSize.large,
    text: google.GSIButtonText.continueWith,
    shape: google.GSIButtonShape.rectangular,
    minimumWidth: width.clamp(100, 400).toDouble(),
    locale: 'id',
  ),
);
