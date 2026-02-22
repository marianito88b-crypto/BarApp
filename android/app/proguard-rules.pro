############################
## uCrop / ImageCropper
############################

# Evitar ofuscación de uCrop
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Evitar ofuscación del plugin de ImageCropper
-keep class vn.hunghd.flutter.plugins.imagecropper.** { *; }
-dontwarn vn.hunghd.flutter.plugins.imagecropper.**

# Si usás ExifInterface para metadatos de imagen
-dontwarn androidx.exifinterface.**


############################
## Flutter video_player / ExoPlayer / Media3
############################

# Plugin video_player de Flutter
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**

# ExoPlayer (usado internamente por video_player en muchas versiones)
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Algunas versiones nuevas usan AndroidX Media3
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**


############################
## Flutter plugins genéricos
############################

# Mantener clases de plugins de Flutter (capa nativa)
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**


############################
## Firebase / Google Play Services / Maps
############################

# Firebase (Auth, Firestore, Storage, etc.)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services (maps, location, etc.)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Maps Android SDK
-keep class com.google.android.libraries.maps.** { *; }
-dontwarn com.google.android.libraries.maps.**


############################
## (Opcional) Evitar problemas extra de warnings
############################

# Evitar warnings innecesarios de Kotlin metadata
-dontwarn kotlin.**
-dontwarn org.jetbrains.annotations.**