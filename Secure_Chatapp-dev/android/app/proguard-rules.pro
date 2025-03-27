# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# WebRTC
-keep class org.webrtc.** { *; }
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class com.twilio.video.** { *; }

# Keep your custom models
-keep class com.securechat.messenger2024.** { *; }

# Don't optimize encryption libraries
-keep class org.bouncycastle.** { *; }
-keep class com.google.crypto.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Support libraries
-keep class androidx.core.app.** { *; }
-keep class androidx.lifecycle.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }

# Prevent proguard from stripping interface information
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes *Annotation* 