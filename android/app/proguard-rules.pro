# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Dart classes used via JNI
-keep class io.flutter.app.** { *; }

# Keep application classes
-keep class id.pantoo.pos.** { *; }

# Gson / JSON serialization
-keepattributes Signature
-keepattributes *Annotation*

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
