import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // Apply Flutter after Android; AGP provides Kotlin support.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

val signingStoreFile = System.getenv("KEYSTORE") ?: keystoreProperties.getProperty("storeFile")
val signingStorePassword = System.getenv("KEYSTORE_PASSWORD") ?: keystoreProperties.getProperty("storePassword")
val signingKeyAlias = System.getenv("KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias")
val signingKeyPassword = System.getenv("KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword")
val hasSigningCredentials = listOf(
    signingStoreFile, signingStorePassword, signingKeyAlias, signingKeyPassword,
).all { !it.isNullOrEmpty() }

android {
    namespace = "net.sunjiao.birdid"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "net.sunjiao.birdid"
        manifestPlaceholders["appLabel"] = "OSEA"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasSigningCredentials) {
                keyAlias = signingKeyAlias
                keyPassword = signingKeyPassword
                storeFile = file(requireNotNull(signingStoreFile))
                storePassword = signingStorePassword
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // Install device tests alongside the user's normal app and data.
            if (providers.gradleProperty("validationBuild").orNull == "true") {
                applicationIdSuffix = ".validation"
                manifestPlaceholders["appLabel"] = "OSEA Validation"
            }
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isShrinkResources = false
            isMinifyEnabled = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

// Debug builds remain available without private release credentials.
val validateReleaseCredentials = tasks.register("validateReleaseCredentials") {
    doLast {
        check(hasSigningCredentials) {
            "Release signing requires KEYSTORE, KEYSTORE_PASSWORD, KEY_ALIAS and KEY_PASSWORD, or android/key.properties."
        }
        check(file(requireNotNull(signingStoreFile)).isFile) {
            "Release keystore does not exist."
        }
    }
}
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(validateReleaseCredentials)
}
