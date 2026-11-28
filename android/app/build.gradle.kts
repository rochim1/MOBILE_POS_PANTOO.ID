import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.tasks.compile.JavaCompile

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    buildFeatures { buildConfig = true }
    namespace = "id.pantoo.pos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "id.pantoo.pos"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    flavorDimensions += "flavor-type"

    productFlavors {
        create("development") {
            dimension = "flavor-type"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Pantoo POS Dev")
        }
        create("staging") {
            dimension = "flavor-type"
            applicationIdSuffix = ".stg"
            resValue("string", "app_name", "Pantoo POS Stg")
        }
        create("qa") {
            dimension = "flavor-type"
            applicationIdSuffix = ".qa"
            resValue("string", "app_name", "Pantoo POS QA")
        }
        // Separate storage/credentials for reproducible two-terminal offline QA.
        // Never reuse staging or clear its data to emulate a second cashier.
        create("qaPeer") {
            dimension = "flavor-type"
            applicationIdSuffix = ".qa.peer"
            resValue("string", "app_name", "Pantoo POS QA Kasir B")
        }
        // Dedicated storage for service-intake GUI QA; preserve all older QA data.
        create("qaService") {
            dimension = "flavor-type"
            applicationIdSuffix = ".qa.service"
            resValue("string", "app_name", "Pantoo POS QA Layanan")
        }
        create("production") {
            dimension = "flavor-type"
            resValue("string", "app_name", "Pantoo POS")
        }
        // Dedicated native Travel GUI storage; never clear or replace older QA.
        create("qaTravel") {
            dimension = "flavor-type"
            applicationIdSuffix = ".qa.travel"
            resValue("string", "app_name", "Pantoo POS QA Travel")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

// Local service-intake QA is isolated from Firebase/production push enrollment.
tasks.matching { it.name.startsWith("processQaService") && it.name.endsWith("GoogleServices") }.configureEach {
    enabled = false
}
tasks.matching { it.name.startsWith("processQaTravel") && it.name.endsWith("GoogleServices") }.configureEach {
    enabled = false
}

// This Flutter SDK generates an integration_test registration in main even
// though its Gradle plugin correctly omits that dev dependency from release.
// Compile a release-only copy; keep the generated original intact for QA/debug
// and never bundle the test plugin in a production APK.
val mainPluginRegistrant = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
val releasePluginRegistrantDir = layout.buildDirectory.dir("generated/posReleasePluginRegistrant")
val preparePOSReleasePluginRegistrant = tasks.register("preparePOSReleasePluginRegistrant") {
    inputs.file(mainPluginRegistrant)
    outputs.dir(releasePluginRegistrantDir)
    doLast {
        val original = mainPluginRegistrant.readText()
        val testRegistration = Regex(
            """(?s)\s*try\s*\{\s*flutterEngine\.getPlugins\(\)\.add\(new dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin\(\)\);\s*\}\s*catch\s*\(Exception e\)\s*\{[^}]*\}"""
        )
        val production = original.replace(testRegistration, "\n")
        check(!production.contains("dev.flutter.plugins.integration_test")) {
            "Unexpected integration_test registration; review the release plugin registrant"
        }
        val output = releasePluginRegistrantDir.get().file("io/flutter/plugins/GeneratedPluginRegistrant.java").asFile
        output.parentFile.mkdirs()
        output.writeText(production)
    }
}
tasks.withType<JavaCompile>().configureEach {
    if (name.endsWith("ReleaseJavaWithJavac")) {
        dependsOn(preparePOSReleasePluginRegistrant)
        inputs.dir(releasePluginRegistrantDir)
        doFirst {
            // Materialize before replacing source: a lazy filter of this task's
            // own source can resolve to an empty collection and omit registration.
            val productionRegistrant = releasePluginRegistrantDir.get()
                .file("io/flutter/plugins/GeneratedPluginRegistrant.java").asFile
            check(productionRegistrant.isFile) { "Production plugin registrant missing" }
            val javaSources = source.files.filter {
                it.canonicalFile != mainPluginRegistrant.canonicalFile &&
                    it.canonicalFile != productionRegistrant.canonicalFile
            }
            setSource(javaSources + productionRegistrant)
        }
        doLast {
            check(destinationDirectory.get().file("io/flutter/plugins/GeneratedPluginRegistrant.class").asFile.isFile) {
                "Release must compile GeneratedPluginRegistrant for Android startup"
            }
        }
    }
}

// Profile choices are fetched at runtime; bundled profiles are offline fallbacks.
// JNI merges must consume the Flutter output after compilation. Without this
// explicit input/order, an incremental APK can retain a previous libapp.so.
tasks.matching { it.name.startsWith("merge") && it.name.endsWith("JniLibFolders") }.configureEach {
    val variantSuffix = name.removePrefix("merge").removeSuffix("JniLibFolders")
    val variantDirectory = variantSuffix.replaceFirstChar { it.lowercaseChar() }
    dependsOn("compileFlutterBuild$variantSuffix")
    inputs.dir(layout.buildDirectory.dir("intermediates/flutter/$variantDirectory/jniLibs"))
}
