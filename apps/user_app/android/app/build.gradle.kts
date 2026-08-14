plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after Android & Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.delivery.user.app"
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.delivery.user.app"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode ?: 1
        versionName = flutter.versionName ?: "0.1.0"
        // Multi-arch APK (smaller than universal, but covers all common devices)
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    buildTypes {
        release {
            // For CI builds without a keystore, use debug signing so APK can still be installed
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
