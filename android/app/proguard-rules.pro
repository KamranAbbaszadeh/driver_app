# --- Flutter ---
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# --- Firebase ---
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# --- Cloud Firestore, Storage, Functions ---
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.tasks.**

# --- Riverpod / Bloc (reflection-safe by default, but keep general rules) ---
-keep class **.bloc.** { *; }
-keepclassmembers class * {
    @**.BlocBuilder <methods>;
    @**.BlocListener <methods>;
}
# --- flutter_background_geolocation ---
-keep class com.transistorsoft.** { *; }
-dontwarn com.transistorsoft.**
# --- image_picker / video_player ---
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**
# --- SharedPreferences / HTTP / intl ---
-keep class androidx.preference.** { *; }
-dontwarn androidx.preference.**
-keep class java.net.** { *; }
-dontwarn java.net.**
-keep class java.text.** { *; }
# --- Google Fonts ---
-keep class com.google.android.gms.fonts.** { *; }
# --- Polyline / UI / Modals ---
-keep class **.flutter_polyline_points.** { *; }
-keep class **.wolt_modal_sheet.** { *; }
-keep class **.flutter_holo_date_picker.** { *; }
# --- General reflection & annotations ---
-keepattributes InnerClasses, EnclosingMethod
-keepattributes Signature
-keepattributes *Annotation*