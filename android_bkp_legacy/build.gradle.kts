buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.6.0"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22"
        classpath "com.google.gms:google-services:4.4.1"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.allprojects {
    tasks.withType(JavaCompile).configureEach {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile).configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}