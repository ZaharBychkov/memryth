import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()

if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

val requiredKeystoreProperties = listOf(
    "storePassword",
    "keyPassword",
    "keyAlias",
    "storeFile",
)
val hasCompleteReleaseKeystore = hasReleaseKeystore &&
    requiredKeystoreProperties.all { !keystoreProperties.getProperty(it).isNullOrBlank() }

if (hasReleaseKeystore && !hasCompleteReleaseKeystore) {
    val missing = requiredKeystoreProperties
        .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
        .joinToString()
    throw GradleException(
        "Release signing is misconfigured. Missing android/key.properties values: $missing"
    )
}

gradle.taskGraph.whenReady {
    val releaseTaskRequested = allTasks.any { task ->
        task.name.contains("Release") &&
            (task.name.startsWith("assemble") || task.name.startsWith("bundle"))
    }
    if (releaseTaskRequested && !hasCompleteReleaseKeystore) {
        throw GradleException(
            "Release builds require android/key.properties and a real upload keystore. " +
                "Copy android/key.properties.example, fill it, and keep the keystore backed up."
        )
    }
}

android {
    namespace = "app.memryth.android"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.memryth.android"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasCompleteReleaseKeystore) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasCompleteReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
