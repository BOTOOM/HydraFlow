pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("flutter_tools_gradle")

    repositories {
        google()
        maven("https://repo.huaweicloud.com/repository/maven/")
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")

gradle.beforeProject {
    buildscript.repositories {
        maven("https://repo.huaweicloud.com/repository/maven/")
        maven("https://plugins.gradle.org/m2")
        mavenCentral()
    }
    repositories {
        maven("https://storage.googleapis.com/download.flutter.io")
        maven("https://repo.huaweicloud.com/repository/maven/")
        mavenCentral()
    }
}
