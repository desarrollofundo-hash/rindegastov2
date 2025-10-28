# Optimizaciones ProGuard para Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Mantener clases del escáner móvil
-keep class dev.steenbakker.mobile_scanner.** { *; }

# Mantener clases de Play Core (para Flutter)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Optimizar pero mantener funcionalidad
-dontwarn kotlin.reflect.**
-keep class kotlin.reflect.** { *; }

# Optimizaciones adicionales
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}