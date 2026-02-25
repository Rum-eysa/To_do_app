plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.todo_app"
    // flutter.compileSdkVersion bazen hata verebilir, garantiye almak için 34 yazabilirsin
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Java 17 kurduğumuz için buraları 17 yapıyoruz
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true 
    }

    kotlinOptions {
        // Burası Java 17 ile uyumlu olmalı
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.todo_app"
        // Değişkenler hata veriyorsa doğrudan rakam yazmak en güvenlisidir:
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}
