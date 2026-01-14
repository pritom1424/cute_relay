# 1. Existing Flutter Rules
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.tasks.**
-dontwarn com.google.android.gms.common.**

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 2. Socket.io & Networking (Crucial for your Chat)
# These prevent the "Minifier" from breaking your connection logic
-keep class io.socket.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn io.socket.**
-dontwarn okhttp3.**
-dontwarn okio.**

# 3. Giphy & Image Picker
# Required so the GIF library can find its own classes at runtime
-keep class com.giphy.** { *; }
-dontwarn com.giphy.**

# 4. JSON Serialization
# Since you use jsonDecode/jsonEncode for messages and Gists
-keepattributes Signature, *Annotation*, EnclosingMethod
-keep class com.google.gson.** { *; }