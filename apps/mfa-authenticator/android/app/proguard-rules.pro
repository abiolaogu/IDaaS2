# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep custom classes used by Flutter
-keep class com.idaas.mfa_authenticator.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# QR Code Scanner
-keep class net.touchcapture.qr.** { *; }

# OTP Library
-dontwarn org.bouncycastle.**
-keep class org.bouncycastle.** { *; }
