buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.4.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    layout.buildDirectory.set(rootProject.rootDir.parentFile.resolve("build/${project.name}"))
}

subprojects {
    afterEvaluate {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                languageVersion = "1.9"
                apiVersion = "1.9"
                jvmTarget = "1.8"
            }
        }
        extensions.findByType<JavaPluginExtension>()?.apply {
            sourceCompatibility = JavaVersion.VERSION_1_8
            targetCompatibility = JavaVersion.VERSION_1_8
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.rootDir.parentFile.resolve("build"))
}
