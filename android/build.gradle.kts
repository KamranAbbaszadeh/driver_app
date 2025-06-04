buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.10.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.10")
        classpath("com.google.gms:google-services:4.4.0")
        classpath("com.google.android.libraries.mapsplatform.secrets-gradle-plugin:secrets-gradle-plugin:2.0.1")
    }
}



allprojects {
    ext {
      set("appCompatVersion", "1.4.2")             
      set("playServicesLocationVersion", "21.3.0") 
       }
    repositories {
        google()
        mavenCentral()  
        // [required] background_geolocation
        maven(url = "${project(":flutter_background_geolocation").projectDir}/libs")
        maven(url = "https://developer.huawei.com/repo/")
        // [required] background_fetch
        maven(url = "${project(":background_fetch").projectDir}/libs")
    }
  }

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
