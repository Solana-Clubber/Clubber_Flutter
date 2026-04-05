# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Solana Mobile Wallet Adapter
-keep class com.solana.** { *; }
-keep class com.solanamobile.** { *; }
-dontwarn com.solana.**

# Naver Map
-keep class com.naver.maps.** { *; }
-dontwarn com.naver.maps.**

# Record plugin (audio)
-keep class com.llfbandit.record.** { *; }

# path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# HTTP / Dart
-keepattributes Signature
-keepattributes *Annotation*

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
