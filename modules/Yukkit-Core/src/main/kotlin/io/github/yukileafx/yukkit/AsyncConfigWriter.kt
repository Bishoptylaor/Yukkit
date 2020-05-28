package io.github.yukileafx.yukkit

import org.bukkit.Bukkit
import org.bukkit.configuration.file.FileConfiguration
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors
import java.util.logging.Level

object AsyncConfigWriter {

    private val executor = Executors.newSingleThreadExecutor { r -> Thread(r, AsyncConfigWriter::class.simpleName) }

    fun write(file: File, config: FileConfiguration) {
        executor.submit {
            val data = config.saveToString()
            kotlin.runCatching {
                file.canonicalFile.parentFile
                        .also { it.mkdirs() }
                        .takeIf { it.isDirectory }
                        ?: throw IOException("Unable to create parent directories.")
                file.writeText(data)
            }.onFailure { e ->
                Bukkit.getLogger().log(Level.SEVERE, "An error occurred while writing to $file.", e)
            }
        }
    }
}
