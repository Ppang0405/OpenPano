# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Add any project specific keep options here:

# Keep native method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep OpenPano classes
-keep class com.openpano.lib.** { *; }
-keepclassmembers class com.openpano.lib.** { *; }

# Keep StitchResult class
-keep class com.openpano.lib.StitchResult { *; }
-keepclassmembers class com.openpano.lib.StitchResult { *; }

# Keep JNI method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep classes that might be accessed via reflection
-keep class com.openpano.lib.OpenPano { *; }
-keepclassmembers class com.openpano.lib.OpenPano { *; }
