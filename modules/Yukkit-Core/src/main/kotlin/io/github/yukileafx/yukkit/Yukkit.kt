package io.github.yukileafx.yukkit

import java.io.IOException
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

object Yukkit {

    @Throws(IOException::class)
    fun fakeWrite() {
    }

    fun newSingleExecutor(threadName: String) =
            ThreadPoolExecutor(1, 1, 0, TimeUnit.MILLISECONDS, ArrayBlockingQueue(1)) { r -> Thread(r, threadName) }
}
