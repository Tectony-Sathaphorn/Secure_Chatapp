allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Add namespace compatibility for plugins
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    // Try to read the AndroidManifest.xml to extract package name
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestContent = manifestFile.readText()
                        val packageRegex = """package=["']([^"']*)["']""".toRegex()
                        val result = packageRegex.find(manifestContent)
                        val packageName = result?.groupValues?.getOrNull(1)
                        
                        if (packageName != null) {
                            // Use reflection to set namespace property
                            val namespaceMethod = android::class.java.methods.find { it.name == "setNamespace" }
                            if (namespaceMethod != null) {
                                val hasNamespaceMethod = android::class.java.methods.find { it.name == "getNamespace" }
                                if (hasNamespaceMethod != null) {
                                    val currentNamespace = hasNamespaceMethod.invoke(android)
                                    if (currentNamespace == null) {
                                        namespaceMethod.invoke(android, packageName)
                                        println("Set namespace for ${project.name} to $packageName")
                                    }
                                } else {
                                    namespaceMethod.invoke(android, packageName)
                                    println("Set namespace for ${project.name} to $packageName")
                                }
                            }
                        }
                    }
                } catch (e: Exception) {
                    println("Failed to set namespace for ${project.name}: ${e.message}")
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
