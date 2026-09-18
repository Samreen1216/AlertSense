import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.plugins.withId("com.android.library") {
        project.extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileSdkVersion(35)
        }
    }
}

subprojects {
    tasks.withType<KotlinCompile>().configureEach {
        val targetCompat = project.extensions.findByType<com.android.build.gradle.BaseExtension>()
            ?.compileOptions
            ?.targetCompatibility
        compilerOptions {
            if (targetCompat == JavaVersion.VERSION_17) {
                jvmTarget.set(JvmTarget.JVM_17)
            } else if (targetCompat == JavaVersion.VERSION_11) {
                jvmTarget.set(JvmTarget.JVM_11)
            } else {
                jvmTarget.set(JvmTarget.JVM_1_8)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
