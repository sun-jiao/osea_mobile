import java.security.MessageDigest

pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        requireNotNull(properties.getProperty("flutter.sdk")) {
            "flutter.sdk not set in local.properties"
        }
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
    id("com.android.application") version "9.0.1" apply false
    // Upgrade AGP's bundled Kotlin compiler without applying the legacy plugin.
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")

// Override only the build script, retaining the hosted plugin's source/resources.
val cameraProject = project(":camerawesome")
val upstreamCameraBuild = cameraProject.projectDir.resolve("build.gradle")
val cameraBuildHash = MessageDigest.getInstance("SHA-256")
    .digest(upstreamCameraBuild.readBytes()).joinToString("") { "%02x".format(it) }
check(cameraBuildHash == "5624b6724bae098e23bad577f8f97e3486fb1e4cf988b64e23063dcd2a20c962") {
    "camerawesome Android build changed. Review android/compat before updating the plugin."
}
cameraProject.buildFileName = file("compat/camerawesome.gradle")
    .relativeTo(cameraProject.projectDir).path
