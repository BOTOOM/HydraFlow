pluginManagement {
    repositories {
        google()
        maven("https://repo.huaweicloud.com/repository/maven/")
        maven("https://storage.googleapis.com/download.flutter.io")
        maven("https://plugins.gradle.org/m2")
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        maven("https://repo.huaweicloud.com/repository/maven/")
        maven("https://storage.googleapis.com/download.flutter.io")
        mavenCentral()
    }
}
