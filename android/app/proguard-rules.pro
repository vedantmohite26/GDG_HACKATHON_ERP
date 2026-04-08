# Flutter ProGuard Rules for UniConnect

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep Gson classes (used by Firebase)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep Flutter plugin registrants
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep Hive classes (used by cache_service)
-keep class com.example.flutter_application_1.** { *; }

# Prevent stripping of error stack traces
-keepattributes SourceFile,LineNumberTable

# Keep Cloudinary SDK classes
-dontwarn org.cloudinary.**
-keep class org.cloudinary.** { *; }
