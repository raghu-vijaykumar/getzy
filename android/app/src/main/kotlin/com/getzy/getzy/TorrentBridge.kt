package com.getzy.getzy

object TorrentBridge {
    private var nativePtr: Long = 0
    private var loaded = false

    fun load() {
        if (loaded) return
        try {
            System.loadLibrary("torrent_bridge")
            loaded = true
        } catch (e: UnsatisfiedLinkError) {
            loaded = false
        }
    }

    val isLoaded: Boolean get() = loaded

    fun createSession(context: android.content.Context): Long {
        if (!loaded) return 0
        val savePath = context.getExternalFilesDir(android.os.Environment.DIRECTORY_DOWNLOADS)
            ?.absolutePath ?: context.filesDir.absolutePath
        nativePtr = nativeCreateSession(savePath)
        return nativePtr
    }

    fun destroySession() {
        if (!loaded || nativePtr == 0L) return
        nativeDestroySession(nativePtr)
        nativePtr = 0
    }

    fun addTorrent(source: String): String {
        if (!loaded || nativePtr == 0L) return ""
        return nativeAddTorrent(nativePtr, source) ?: ""
    }

    fun removeTorrent(infoHash: String) {
        if (!loaded || nativePtr == 0L) return
        nativeRemoveTorrent(nativePtr, infoHash)
    }

    fun pauseTorrent(infoHash: String) {
        if (!loaded || nativePtr == 0L) return
        nativePauseTorrent(nativePtr, infoHash)
    }

    fun resumeTorrent(infoHash: String) {
        if (!loaded || nativePtr == 0L) return
        nativeResumeTorrent(nativePtr, infoHash)
    }

    fun pauseAll() {
        if (!loaded || nativePtr == 0L) return
        nativePauseAll(nativePtr)
    }

    fun resumeAll() {
        if (!loaded || nativePtr == 0L) return
        nativeResumeAll(nativePtr)
    }

    fun getTorrentStatuses(): Array<String> {
        if (!loaded || nativePtr == 0L) return emptyArray()
        return nativeGetTorrentStatuses(nativePtr) ?: emptyArray()
    }

    fun applySettings(settingsJson: String) {
        if (!loaded || nativePtr == 0L) return
        nativeApplySettings(nativePtr, settingsJson)
    }

    fun setFilePriorities(infoHash: String, selectedFiles: Array<String>) {
        if (!loaded || nativePtr == 0L) return
        nativeSetFilePriorities(nativePtr, infoHash, selectedFiles)
    }

    private external fun nativeCreateSession(savePath: String): Long
    private external fun nativeDestroySession(ptr: Long)
    private external fun nativeAddTorrent(ptr: Long, source: String): String?
    private external fun nativeRemoveTorrent(ptr: Long, infoHash: String)
    private external fun nativePauseTorrent(ptr: Long, infoHash: String)
    private external fun nativeResumeTorrent(ptr: Long, infoHash: String)
    private external fun nativePauseAll(ptr: Long)
    private external fun nativeResumeAll(ptr: Long)
    private external fun nativeGetTorrentStatuses(ptr: Long): Array<String>?
    private external fun nativeApplySettings(ptr: Long, settingsJson: String)
    private external fun nativeSetFilePriorities(ptr: Long, infoHash: String, selectedFiles: Array<String>)
}
