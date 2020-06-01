package io.github.yukileafx.yukkit

import com.electronwill.nightconfig.core.Config
import com.electronwill.nightconfig.core.file.FileConfig
import org.bukkit.configuration.file.YamlConfiguration
import java.nio.file.Files
import java.nio.file.Paths
import java.util.*
import kotlin.streams.asSequence

object Settings {

    private val settings = mutableListOf<FileConfig>()

    private fun configWithResource(file: String, resource: String) =
            FileConfig.builder(Paths.get(file)).defaultResource(resource).build()

    fun load() {
        val dir = Paths.get("settings")

        Files.createDirectories(dir)

        val resourceSeq = sequenceOf(
                configWithResource("settings/yukkit.toml", "/yukkit.toml"),
                configWithResource("settings/bungee.toml", "/bungee.toml")
        )

        val fileSeq = Files.list(dir)
                .map { kotlin.runCatching { FileConfig.of(it) }.getOrNull() }
                .asSequence()
                .filterNotNull()

        (resourceSeq + fileSeq)
                .distinctBy { it.nioPath }
                .onEach { println("Yukkit >> Loading ${it.nioPath}...") }
                .onEach { it.load() }
                .forEach { settings += it }

        loadAfter()
    }

    private fun loadAfter() {
        println("Yukkit >> Sorting settings...")
        settings.sortBy { it.getIntOrElse("weight", 0) }

        println("Yukkit >> Disabling unnecessary settings...")
        settings.removeIf {
            it.get<Config>("if system property")
                    ?.valueMap()
                    ?.any { entry -> entry.value != System.getProperty(entry.key) }
                    ?: false
        }

        settings.onEach { println("Yukkit >> Loaded ${it.nioPath}") }
    }

    fun apply(name: String, action: (key: String, value: Any) -> Unit) {
        println("${"-".repeat(16)} [ Yukkit @ $name ] ${"-".repeat(16)}")
        settings
                .flatMap { it.get<Config>(listOf(name))?.valueMap()?.entries ?: mutableSetOf() }
                .onEach { entry -> println("${entry.key} = ${entry.value}") }
                .forEach { entry -> action.invoke(entry.key, entry.value) }
    }

    fun applyFlags() {
        apply("system property") { key, value -> System.setProperty(key, value.toString()) }
    }

    fun applyYaml(name: String, yaml: YamlConfiguration) {
        apply(name) { key, value -> yaml.set(key, value) }
    }

    fun applyProperties(name: String, prop: Properties) {
        apply(name) { key, value -> prop.setProperty(key, value.toString()) }
    }
}
