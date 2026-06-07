# Real Torrent Engine: libtorrent Integration Plan

**Created**: 2026-06-07  
**Approach**: Native libtorrent C++ via Flutter plugin (JNI)

---

## Architecture Overview

```
┌─────────────────────────────────────┐
│           Flutter (Dart)             │
│  ┌───────────────────────────────┐  │
│  │   RealTorrentEngine           │  │
│  │   - implements TorrentEngine  │  │
│  │   - MethodChannel → native    │  │
│  │   - EventChannel ← native     │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │   TorrentHomeScreen          │  │
│  │   Settings, Feeds, etc.      │  │
│  └───────────────────────────────┘  │
└──────────────┬──────────────────────┘
               │ MethodChannel / EventChannel
┌──────────────▼──────────────────────┐
│          Android (Kotlin)            │
│  ┌───────────────────────────────┐  │
│  │   TorrentEnginePlugin.kt     │  │
│  │   - MethodChannel handler     │  │
│  │   - EventChannel sink         │  │
│  │   - Delegates to JNI bridge   │  │
│  └───────────┬───────────────────┘  │
│  ┌───────────▼───────────────────┐  │
│  │   LibtorrentBridge (JNI)      │  │
│  │   - C++ wrapper around        │  │
│  │     libtorrent session        │  │
│  └───────────┬───────────────────┘  │
│  ┌───────────▼───────────────────┐  │
│  │   libtorrent (C++)            │  │
│  │   - Session management        │  │
│  │   - DHT, tracker, peer I/O    │  │
│  │   - Piece downloading/disk IO │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## Phase 1: libtorrent Build System

### 1.1 Cross-compile libtorrent for Android

libtorrent (https://github.com/arvidn/libtorrent) uses Boost.Asio and Boost.system. It must be cross-compiled for Android architectures.

**Required architectures**: arm64-v8a, armeabi-v7a, x86_64

**Steps**:
1. Install NDK (r25+)
2. Build Boost for Android (or use header-only subsets)
3. Configure libtorrent with CMake toolchain:
   ```cmake
   cmake -B build-android \
     -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
     -DANDROID_ABI=arm64-v8a \
     -DCMAKE_BUILD_TYPE=Release \
     -DCMAKE_INSTALL_PREFIX=../install/arm64-v8a
   cmake --build build-android --target install
   ```
4. Repeat for each ABI.
5. Strip debug symbols from `.so` files.

**Output**: `libtorrent.so` + `libtorrent-rasterbar.so` per ABI, placed at:
```
android/app/src/main/jniLibs/
├── arm64-v8a/
│   └── libtorrent-rasterbar.so
├── armeabi-v7a/
│   └── libtorrent-rasterbar.so
└── x86_64/
    └── libtorrent-rasterbar.so
```

### 1.2 Create JNI bridge C++ library

A thin C++ library that exposes JNI functions to call libtorrent:

**`torrent_bridge.cpp`** key functions:
```cpp
extern "C" JNIEXPORT jlong JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeCreateSession(
    JNIEnv* env, jobject thiz);

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeAddTorrent(
    JNIEnv* env, jobject thiz, jlong session_ptr, jstring source);

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeRemoveTorrent(
    JNIEnv* env, jobject thiz, jlong session_ptr, jstring info_hash);

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativePause(
    JNIEnv* env, jobject thiz, jlong session_ptr, jstring info_hash);

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeResume(
    JNIEnv* env, jobject thiz, jlong session_ptr, jstring info_hash);

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeGetTorrentStatus(
    JNIEnv* env, jobject thiz, jlong session_ptr);
```

**Build**: Also compiled with NDK into `libtorrent_bridge.so`.

---

## Phase 2: Kotlin Bridge Layer

### 2.1 TorrentBridge.kt

A Kotlin singleton that loads the native library and manages the libtorrent session pointer:

```kotlin
object TorrentBridge {
    init {
        System.loadLibrary("torrent_bridge")
    }

    private var sessionPtr: Long = 0

    fun startSession(settings: Map<String, Any>) {
        if (sessionPtr == 0L) {
            sessionPtr = nativeCreateSession()
            applySettings(settings)
        }
    }

    fun stopSession() {
        if (sessionPtr != 0L) {
            nativeDestroySession(sessionPtr)
            sessionPtr = 0L
        }
    }

    fun addTorrent(source: String): String {
        return nativeAddTorrent(sessionPtr, source)
    }

    // ... bridge methods

    private external fun nativeCreateSession(): Long
    private external fun nativeDestroySession(ptr: Long)
    private external fun nativeAddTorrent(ptr: Long, source: String): String
    private external fun nativeRemoveTorrent(ptr: Long, infoHash: String)
    private external fun nativePauseTorrent(ptr: Long, infoHash: String)
    private external fun nativeResumeTorrent(ptr: Long, infoHash: String)
    private external fun nativeGetTorrentStatuses(ptr: Long): Array<TorrentStatusData>
}
```

### 2.2 TorrentEnginePlugin.kt

A Flutter plugin handler registered in `MainActivity.kt`:

```kotlin
class TorrentEnginePlugin(
    private val messenger: BinaryMessenger,
    private val context: Context
) {
    private val methodChannel = MethodChannel(messenger, "getzy/torrent_engine")
    private val eventChannel = EventChannel(messenger, "getzy/torrent_engine_events")
    private var eventSink: EventChannel.EventSink? = null
    private var pollTimer: Timer? = null

    fun start() {
        methodChannel.setMethodCallHandler(::handleMethodCall)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                TorrentBridge.startSession(call.arguments as? Map<String, Any> ?: emptyMap())
                startPolling()
                result.success(null)
            }
            "addTorrent" -> {
                val source = call.argument<String>("source") ?: return result.error(...)
                val infoHash = TorrentBridge.addTorrent(source)
                result.success(infoHash)
            }
            "toggleTorrent" -> {
                val id = call.argument<String>("id") ?: return ...
                TorrentBridge.toggleTorrent(id)
                result.success(null)
            }
            "pauseAll" -> { TorrentBridge.pauseAll(); result.success(null) }
            "resumeAll" -> { TorrentBridge.resumeAll(); result.success(null) }
            "shutdown" -> { stopPolling(); TorrentBridge.stopSession(); result.success(null) }
            "deleteTorrent" -> {
                val id = call.argument<String>("id") ?: return ...
                TorrentBridge.removeTorrent(id)
                result.success(null)
            }
            // ... bandwidth, protocol, encryption settings
            else -> result.notImplemented()
        }
    }

    private fun startPolling() {
        pollTimer = Timer("TorrentPoll", true).apply {
            schedule(object : TimerTask() {
                override fun run() {
                    val statuses = TorrentBridge.getTorrentStatuses()
                    val json = JSONArray(statuses.map { it.toMap() }).toString()
                    handler.post { eventSink?.success(json) }
                }
            }, 0, 1000) // poll every 1s
        }
    }
}
```

### 2.3 Update MainActivity.kt

Register the plugin alongside existing `TorrentForegroundService` handling:

```kotlin
class MainActivity : FlutterActivity() {
    private lateinit var enginePlugin: TorrentEnginePlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        enginePlugin = TorrentEnginePlugin(
            flutterEngine.dartExecutor.binaryMessenger,
            this
        )
        enginePlugin.start()
    }
}
```

Move existing `MethodChannel` handling for `isAvailable`, `startService`, `stopService`, `updateNotification` into `TorrentEnginePlugin`.

---

## Phase 3: Dart-Side RealTorrentEngine

### 3.1 RealTorrentEngine class

Create `lib/features/torrents/real_torrent_engine.dart`:

```dart
class RealTorrentEngine extends TorrentEngine {
  static const _channel = MethodChannel('getzy/torrent_engine');
  static const _eventChannel = EventChannel('getzy/torrent_engine_events');

  final StreamController<TorrentEngineEvent> _eventController =
      StreamController<TorrentEngineEvent>.broadcast();
  final TorrentRepository _repository = TorrentRepository.instance;

  List<TorrentTask> _torrents = [];
  TorrentEngineState _state = TorrentEngineState.initializing;
  TorrentSortOption _sortOption = TorrentSortOption.queueNumber;
  bool _isShutdown = false;
  StreamSubscription? _eventSub;

  @override
  Stream<TorrentEngineEvent> get events => _eventController.stream;

  @override
  Future<void> initialize() async {
    _eventSub = _eventChannel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (error) {
        _state = TorrentEngineState.crashed;
        _emitEvent(TorrentEngineErrorEvent(error.toString()));
        notifyListeners();
      },
    );

    try {
      await _channel.invokeMethod('initialize');
      _state = TorrentEngineState.running;
    } on MissingPluginException {
      _state = TorrentEngineState.crashed;
      _emitEvent(TorrentEngineErrorEvent('Native engine not available'));
    }

    try {
      _torrents = await _repository.loadTorrents();
    } catch (_) {}

    _emitEvent(TorrentEngineStateChanged(_state));
    notifyListeners();
  }

  void _onNativeEvent(dynamic event) {
    // Parse JSON array of torrent statuses from native side
    // Update _torrents list, emit TorrentTaskUpdated events
    // Handle state changes, errors
  }

  @override
  Future<void> addTorrent(String source) async {
    try {
      final infoHash = await _channel.invokeMethod<String>(
        'addTorrent',
        {'source': source},
      );
      // Native engine will push status updates via event channel
      // Torrent will appear in next poll cycle
    } on PlatformException catch (e) {
      throw TorrentInputException(e.message ?? 'Failed to add torrent');
    }
  }

  @override
  Future<void> shutdown() async {
    if (_isShutdown) return;
    _isShutdown = true;
    _state = TorrentEngineState.shutdown;
    await _eventSub?.cancel();
    try {
      await _channel.invokeMethod('shutdown');
    } catch (_) {}
    _emitEvent(TorrentEngineStateChanged(_state));
    notifyListeners();
  }

  // ... remaining method implementations delegate to MethodChannel
}
```

### 3.2 TorrentStatusData model

A Kotlin data class that maps to the Dart `TorrentTask` fields:

```kotlin
data class TorrentStatusData(
    val infoHash: String,
    val name: String,
    val status: String,        // "downloading", "paused", "finished", etc.
    val progress: Double,      // 0.0 - 1.0
    val downloadedBytes: Long,
    val totalBytes: Long,
    val downloadSpeed: Int,    // bytes/sec
    val uploadSpeed: Int,      // bytes/sec
    val eta: Long,             // seconds
    val numPeers: Int,
    val numSeeds: Int,
    val queuePosition: Int,
    val errorMessage: String?,
)
```

---

## Phase 4: File Selection Dialog

### 4.1 Flow

1. User taps "Add torrent" → enters magnet/URL/file
2. **Native**: libtorrent adds torrent, resolves metadata
3. **Native → Dart**: EventChannel sends `awaiting_file_selection` event with file list
4. **Dart**: `RealTorrentEngine` receives event, emits `TorrentAwaitingFileSelection` event
5. **UI**: Dialog/bottom sheet shows file list with checkboxes
6. **User**: selects files, taps "Start download"
7. **Dart → Native**: MethodChannel `setFilePriorities(infoHash, selectedIndices)`
8. **Native**: libtorrent sets file priorities to 0 for deselected files, starts download

### 4.2 New event types

```dart
class TorrentAwaitingFileSelection extends TorrentEngineEvent {
  final String infoHash;
  final String name;
  final List<TorrentFile> files;
}

class TorrentMetadataResolved extends TorrentEngineEvent {
  final String infoHash;
  final String name;
  final List<TorrentFile> files;
}
```

### 4.3 File selection UI (FR-002)

Create `lib/features/torrents/file_selection_screen.dart`:

- Full-screen dialog with:
  - Title: torrent name
  - File list with checkboxes, file sizes
  - Select all / deselect all
  - "Start download" button
- On confirm: send selected file indices to native engine

---

## Phase 5: Integration Steps

### 5.1 Swap engine in GetzyApp

```dart
// getzy_app.dart
TorrentEngine _createEngine() {
  if (useRealEngine) {
    return RealTorrentEngine();
  }
  return FakeTorrentEngine.seeded();
}
```

Detection of real engine availability via platform channel:

```dart
final available = await TorrentEnginePlatform.isAvailable();
```

### 5.2 State migration

When switching from fake to real:
1. Clear fake database state
2. Seed with real torrents loaded from libtorrent resume data
3. UI reacts identically since both implement `TorrentEngine`

### 5.3 Settings propagation

On `initialize()`, send all persisted settings to native engine:

```dart
await _channel.invokeMethod('applySettings', {
  'max_download_speed': await _settingsRepo.loadValue('max_download_speed') ?? '0',
  'max_upload_speed': await _settingsRepo.loadValue('max_upload_speed') ?? '0',
  'enable_dht': await _settingsRepo.loadValue('enable_dht') ?? 'true',
  'enable_lsd': await _settingsRepo.loadValue('enable_lsd') ?? 'true',
  'enable_upnp': await _settingsRepo.loadValue('enable_upnp') ?? 'true',
  'enable_nat_pmp': await _settingsRepo.loadValue('enable_nat_pmp') ?? 'true',
  'enable_pex': await _settingsRepo.loadValue('enable_pex') ?? 'true',
  'enable_utp': await _settingsRepo.loadValue('enable_utp') ?? 'true',
  'listening_port': await _settingsRepo.loadValue('listening_port') ?? '55623',
  'random_port': await _settingsRepo.loadValue('random_port') ?? 'true',
  'storage_path': await _settingsRepo.loadValue('storage_path') ?? defaultPath,
  'encryption_level': await _settingsRepo.loadValue('encryption_level') ?? 'enabled',
});
```

### 5.4 Power management

- **shutdown_when_complete**: Native engine checks `state.is_finished` for all torrents, calls `session.pause()`
- **keep_cpu_aware**: Acquire Android `WakeLock` via `PowerManager`
- **keep_running_background**: Foreground service runs with `START_STICKY`

---

## libtorrent Feature Mapping

| Setting | libtorrent API |
|---------|---------------|
| Max download speed | `settings_pack::download_rate_limit` |
| Max upload speed | `settings_pack::upload_rate_limit` |
| Max connections | `settings_pack::connections_limit` |
| DHT on/off | `session::start_dht()` / `session::stop_dht()` |
| LSD on/off | `session::start_lsd()` / `session::stop_lsd()` |
| UPnP on/off | `session::start_upnp()` / `session::stop_upnp()` |
| NAT-PMP on/off | `session::start_natpmp()` / `session::stop_natpmp()` |
| PEX on/off | `torrent_handle::set_peer_classes()` or `add_extension()` |
| uTP on/off | `settings_pack::enable_outgoing_utp`, `enable_incoming_utp` |
| Encryption level | `settings_pack::pe_settings` (`pe_settings::pe_disabled`, `pe_enabled`, `pe_forced`) |
| Proxy | `settings_pack::proxy_type`, `proxy_hostname`, `proxy_port`, `proxy_username`, `proxy_password` |
| IP filter | `session::set_ip_filter()` |
| Random port | `settings_pack::listen_port` = 0, `random_listen_port` = true |
| Storage path | `torrent_handle::save_resume_data()` / add_torrent_params::save_path |
| Sequential download | `torrent_handle::set_sequential_download(true)` |

---

## Migration Path

1. **Phase 1**: Build libtorrent for Android, create JNI bridge → CI produces `.so` files
2. **Phase 2**: Implement Kotlin `TorrentBridge` + `TorrentEnginePlugin` → MethodChannel works
3. **Phase 3**: Implement `RealTorrentEngine` in Dart → all TorrentEngine methods call through
4. **Phase 4**: Implement EventChannel polling → live torrent status in UI
5. **Phase 5**: File selection dialog → full magnet → files → download flow
6. **Phase 6**: Settings propagation + power management → full feature parity
7. **Phase 7**: Remove `FakeTorrentEngine.seeded()`, use real engine by default

Each phase has a working app — phases 1-2 produce a buildable APK, phases 3+ show live torrent state in UI.

---

## Build Requirements

- **Android NDK r25+** — for cross-compiling libtorrent and the JNI bridge
- **CMake 3.21+** — for libtorrent build system
- **Boost 1.83+** — libtorrent dependency (can use header-only subset)
- **OpenSSL** — for libtorrent's crypto needs (optional, can disable)
- **Gradle 8.x** — already configured
- **Kotlin 1.9+** — already configured

### Gradle dependency for prebuilt libs

```gradle
android {
    sourceSets.main {
        jniLibs.srcDirs = ['src/main/jniLibs']
    }
}
```

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| libtorrent build complex | High | Use prebuilt binaries from Conan/GitHub Actions |
| NDK version mismatch | Medium | Pin NDK version, use Docker build image |
| JNI threading errors | High | Use dedicated event loop thread, `AttachCurrentThread` |
| MethodChannel data limits | Low | Batch status updates, use JSON serialization |
| Memory usage from many torrents | Medium | libtorrent handles this well; limit to 500 |
| APK size increase | Medium | libtorrent `.so` ~5MB per ABI, strip debug symbols |
