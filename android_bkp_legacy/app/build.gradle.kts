// android/build.gradle  (GROOVY)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.6.0'
        classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.23'
        classpath 'com.google.gms:google-services:4.4.1'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

/**
 * Fuerza Java 17 y Kotlin jvmTarget=17 en TODOS los subproyectos
 * que sean LIBRERÍAS (plugins de terceros).
 * * El módulo ':app' (que es KTS) se configurará en su propio archivo.
 */
subprojects { subproj ->
    
    // --- ESTA ES LA LÓGICA ANTERIOR (que falló) ---
    // plugins.withId('com.android.library') {
    //     android { ... }
    //     plugins.withId('org.jetbrains.kotlin.android') {
    //         kotlin { ... }
    //     }
    // }
    
    // --- INICIO DE LA NUEVA LÓGICA (paralela) ---

    // 1. Configura Java 17 para TODAS las librerías Android (Java o Kotlin)
    plugins.withId('com.android.library') {
        android {
            compileOptions {
                sourceCompatibility JavaVersion.VERSION_17
                targetCompatibility JavaVersion.VERSION_17
            }
        }
    }
    
    // 2. Configura el Toolchain para TODAS las librerías Kotlin-Android
    //    Esto debería pillar a 'sign_in_with_apple' y resolver el
    //    conflicto Java (11) vs Kotlin (17).
    plugins.withId('org.jetbrains.kotlin.android') {
        kotlin {
            jvmToolchain(17)
        }
    }

    // 3. Fallbacks (los mismos que teníamos, son un buen seguro)
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile).configureEach {
        kotlinOptions {
            jvmTarget = '17'
        }
    }

    tasks.withType(JavaCompile).configureEach {
        sourceCompatibility = '17'
        targetCompatibility = '17'
    }
}

tasks.register("clean", Delete) {
    delete rootProject.layout.buildDirectory
}