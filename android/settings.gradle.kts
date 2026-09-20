try {
    val processEnvClass = Class.forName("java.lang.ProcessEnvironment")
    val envField = processEnvClass.getDeclaredField("theCaseInsensitiveEnvironment")
    envField.isAccessible = true
    (envField.get(null) as? MutableMap<*, *>)?.let { map ->
        val keysToRemove = map.keys.filter { it.toString().equals("ANDROID_PREFS_ROOT", ignoreCase = true) }
        keysToRemove.forEach { map.remove(it) }
    }
} catch (_: Throwable) {}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
