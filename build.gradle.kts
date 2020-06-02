import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar
import com.github.jengelman.gradle.plugins.shadow.transformers.Log4j2PluginsCacheFileTransformer
import groovy.lang.Closure
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.palantir.git-version") version "0.12.3"
    kotlin("jvm") version "1.3.72" apply false
    id("com.github.johnrengelman.shadow") version "5.2.0" apply false
}

group = "io.github.yukileafx"
version = "1.12.2-R0.1-SNAPSHOT"

val gitVersion = (extensions.extraProperties.get("gitVersion") as? Closure<*>)?.call() ?: "unknown"

subprojects {
    group = parent?.group.toString()
    version = parent?.version.toString()
}

project(":modules:Yukkit-Core") {
    apply(plugin = "org.jetbrains.kotlin.jvm")
    apply(plugin = "com.github.johnrengelman.shadow")

    repositories {
        mavenCentral()
        maven("https://papermc.io/repo/repository/maven-public/")
    }

    dependencies {
        "implementation"(kotlin("stdlib-jdk8"))
        "compileOnly"("com.destroystokyo.paper:paper-api:$version")
        "api"("com.electronwill.night-config:toml:3.6.3")
    }

    tasks.withType<KotlinCompile> {
        kotlinOptions {
            jvmTarget = "1.8"
        }
    }

    tasks.withType<ProcessResources> {
        filesMatching("**/version.properties") {
            filter {
                it.replace("@version", version.toString())
            }
        }
    }

    tasks.withType<ShadowJar> {
        minimize()
    }
}

project(":modules:Yukkit-API") {
    apply(plugin = "java-library")
    apply(plugin = "com.github.johnrengelman.shadow")

    repositories {
        mavenCentral()
        maven("https://hub.spigotmc.org/nexus/content/groups/public/")
        maven("https://papermc.io/repo/repository/maven-public/")
        maven("https://oss.sonatype.org/content/groups/public/")
    }

    dependencies {
        // Yukkit-API
        "api"(project(":modules:Yukkit-Core"))

        // Paper-API
        "implementation"("com.google.code.findbugs:jsr305:1.3.9")
        "compileOnly"("net.sf.trove4j:trove4j:3.0.3")
        "compileOnly"("co.aikar:fastutil-lite:1.0")
        "implementation"("org.ow2.asm:asm:6.1.1")
        "implementation"("org.ow2.asm:asm-commons:6.1.1")
        "implementation"("com.mojang:authlib:1.5.25")
        "implementation"("org.slf4j:slf4j-api:1.7.25")

        // Spigot-API
        "api"("net.md-5:bungeecord-chat:1.12-SNAPSHOT") // Yukkit

        // Bukkit
        "api"("commons-lang:commons-lang:2.6") // Yukkit
        "implementation"("com.googlecode.json-simple:json-simple:1.1.1")
        "api"("com.google.guava:guava:29.0-jre") // Yukkit
        "implementation"("com.google.code.gson:gson:2.8.0")
        "api"("org.yaml:snakeyaml:1.26") // Yukkit
        "testImplementation"("junit:junit:4.12")
        "testImplementation"("org.hamcrest:hamcrest-library:1.3")
    }

    configurations {
        create("depends")
    }

    artifacts {
        add("depends", tasks["shadowJar"])
    }

    tasks.withType<JavaCompile> {
        sourceCompatibility = "1.8"
        targetCompatibility = "1.8"
        options.encoding = "UTF-8"
    }

    tasks.withType<ShadowJar> {
        dependencies {
            exclude(dependency("junit:junit:.*"))
            exclude(dependency("org.hamcrest:hamcrest-library:.*"))
        }

        minimize()
    }
}

project(":modules:Yukkit-Server") {
    apply(plugin = "java-library")
    apply(plugin = "com.github.johnrengelman.shadow")

    repositories {
        mavenLocal()
        mavenCentral()
        maven("https://hub.spigotmc.org/nexus/content/groups/public/")
        maven("https://papermc.io/repo/repository/maven-public/")
    }

    dependencies {
        // Yukkit-Server
        "api"(project(":modules:Yukkit-API", configuration = "depends"))

        // Paper
        "api"("net.minecrell:terminalconsoleappender:1.1.1") // Yukkit
        "api"("net.java.dev.jna:jna:4.5.2") // Yukkit
        "api"("org.apache.logging.log4j:log4j-core:2.8.1") // Yukkit
        "implementation"("org.apache.logging.log4j:log4j-iostreams:2.8.1")
        "runtimeOnly"("org.apache.logging.log4j:log4j-slf4j-impl:2.8.1")
        "runtimeOnly"("com.lmax:disruptor:3.4.2")

        // Spigot
        "implementation"("net.sf.trove4j:trove4j:3.0.3")

        // CraftBukkit
        "api"("io.netty:netty-all:4.1.50.Final") // Yukkit
        "implementation"("org.spigotmc:minecraft-server:1.12.2-SNAPSHOT")
        "implementation"("net.sf.jopt-simple:jopt-simple:5.0.4")
        "api"("jline:jline:2.12.1") // Yukkit
        "runtimeOnly"("org.xerial:sqlite-jdbc:3.21.0.1")
        "runtimeOnly"("mysql:mysql-connector-java:5.1.45")
        "testImplementation"("junit:junit:4.12")
        "testImplementation"("org.hamcrest:hamcrest-library:1.3")
    }

    tasks.withType<JavaCompile> {
        sourceCompatibility = "1.8"
        targetCompatibility = "1.8"
        options.encoding = "UTF-8"
    }

    tasks.withType<ShadowJar> {
        transform(Log4j2PluginsCacheFileTransformer())

        relocate("jline", "org.bukkit.craftbukkit.libs.jline")
        relocate("org.bukkit.craftbukkit", "org.bukkit.craftbukkit.v1_12_R1")
        relocate("net.minecraft.server", "net.minecraft.server.v1_12_R1")

        manifest {
            attributes["Main-Class"] = "org.bukkit.craftbukkit.v1_12_R1.Main"
            attributes["Implementation-Title"] = "CraftBukkit"
            attributes["Implementation-Version"] = gitVersion
        }

        dependencies {
            exclude(dependency("junit:junit:.*"))
            exclude(dependency("org.hamcrest:hamcrest-library:.*"))
        }

        minimize()
    }
}
