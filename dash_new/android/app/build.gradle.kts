// ===== IMPORTS NECESARIOS =====
import java.util.Properties
import java.io.FileInputStream

// ===== CARGA DE key.properties (antes de android { }) =====
val keystorePropsFile = rootProject.file("key.properties")
val keystoreProps = Properties().apply {
    if (keystorePropsFile.exists()) {
        FileInputStream(keystorePropsFile).use { this.load(it) }
    }
}

// ===== PLUGINS =====
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ===== ANDROID =====
android {
    namespace = "com.example.dash"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.dash"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = "17" }

    // Firma RELEASE
    signingConfigs {
        create("release") {
            // Estos valores vienen de key.properties
            if (keystorePropsFile.exists()) {
                storeFile = file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
            }
        }
    }
buildTypes {
    release {
        isMinifyEnabled = false       // ← OFF
        isShrinkResources = false     // ← OFF
        signingConfig = signingConfigs.getByName("release")
    }
    debug { }
}

}

// ===== DEPENDENCIAS =====
dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// ===== FLUTTER SOURCE =====
flutter {
    source = "../.."
}
