# Meep release ProGuard/R8 keep rules.
# Giu symbol cho Crashlytics symbolication + chan R8 strip reflection-based SDK.

# Crashlytics: giu line number + source file cho stacktrace doc duoc.
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*

# Flutter engine + embedding (deferred components, plugin registrant).
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
# Flutter embedding tham chieu Play Core (deferred components / split install)
# nhung app khong dung -> R8 bao missing class. App khong split nen dontwarn an toan.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Firebase (Auth/Firestore/Storage/Messaging/Crashlytics) — reflection noi bo.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Sign-In.
-keep class com.google.android.gms.auth.** { *; }

# WorkManager + widget native (WidgetSyncWorker chay qua reflection cua WorkManager).
-keep class androidx.work.** { *; }
-keep class dev.meep.meep.** { *; }

# Glide (annotation processor sinh GeneratedAppGlideModule, load qua reflection).
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule { <init>(...); }
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** { **[] $VALUES; public *; }

# Kotlin coroutines.
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
-dontwarn kotlinx.coroutines.**
