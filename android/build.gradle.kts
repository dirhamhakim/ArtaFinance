allprojects {
    repositories {
        // Cache opsional dari server resmi Flutter, dipakai bila unduhan Gradle timeout.
        val engineCache = rootProject.file("../.tooling/flutter-maven")
        if (engineCache.resolve(".ready").isFile) {
            maven {
                url = engineCache.toURI()
                content { includeGroup("io.flutter") }
            }
        }
        google()
        mavenCentral()
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
