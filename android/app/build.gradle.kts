plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.selddon.contextual"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        freeCompilerArgs += listOf("-Xskip-metadata-version-check")
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.selddon.contextual"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        release {
            storeFile file('release-key.jks')
            storePassword '@@22anakin31'
            keyAlias 'chave_release'
            keyPassword '@@22anakin31'
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
                    minifyEnabled true
            shrinkResources true
        }
        debug {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Adicionar a dependência de desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
    // outras dependências...
}
