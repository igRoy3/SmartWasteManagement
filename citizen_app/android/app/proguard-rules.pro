# Proguard rules for release builds
# Keep model classes
-keep class com.smartwaste.citizen.models.** { *; }

# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# HTTP/Network
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
