import groovy.lang.Closure

plugins {
    id("com.palantir.git-version") version "0.12.3"
}

group = "io.github.yukileafx"
version = "1.12.2-R0.1-SNAPSHOT"

subprojects {
    group = parent?.group.toString()
    version = parent?.version.toString()
}

val gitVersion = (extensions.extraProperties.get("gitVersion") as? Closure<*>)?.call() ?: "unknown"
val softwareVersion = "git-Yukkit-$gitVersion"

allprojects {
    ext {
        set("softwareVersion", softwareVersion)
    }
}
