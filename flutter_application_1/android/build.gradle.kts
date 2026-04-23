buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.4.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    layout.buildDirectory.set(rootProject.rootDir.parentFile.resolve("build/${project.name}"))
}

tasks.register<Delete>("clean") {
    delete(rootProject.rootDir.parentFile.resolve("build"))
}
