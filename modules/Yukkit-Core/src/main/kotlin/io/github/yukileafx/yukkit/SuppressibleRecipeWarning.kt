package io.github.yukileafx.yukkit

class SuppressibleRecipeWarning(msg: String) {

    private val thrown = Throwable(msg)

    fun printStackTrace() {
        val trace = Thread.currentThread().stackTrace
        val opts = System.getProperty("yukkit.suppress-recipe-warning")?.split(",")
        if (opts?.none { method -> trace.any { method == "${it.className}.${it.methodName}" } } != false) {
            thrown.printStackTrace()
        }
    }
}
