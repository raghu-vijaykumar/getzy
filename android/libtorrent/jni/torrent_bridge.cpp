#include <jni.h>
#include <string>
#include <vector>
#include <map>

#include <libtorrent/session.hpp>
#include <libtorrent/add_torrent_params.hpp>
#include <libtorrent/torrent_handle.hpp>
#include <libtorrent/torrent_status.hpp>
#include <libtorrent/alert_types.hpp>
#include <libtorrent/settings_pack.hpp>
#include <libtorrent/error_code.hpp>
#include <libtorrent/magnet_uri.hpp>

static lt::session* g_session = nullptr;
static JavaVM* g_jvm = nullptr;
static jobject g_callback = nullptr;
static jmethodID g_onStatusUpdate = nullptr;

extern "C" JNIEXPORT jint JNICALL
JNI_OnLoad(JavaVM* vm, void* reserved) {
    g_jvm = vm;
    return JNI_VERSION_1_6;
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeCreateSession(
    JNIEnv* env, jobject thiz) {
    if (g_session) {
        delete g_session;
    }
    lt::settings_pack pack;
    pack.set_int(lt::settings_pack::alert_mask, lt::alert::status_notification |
        lt::alert::error_notification | lt::alert::progress_notification);
    g_session = new lt::session(pack);
    g_session->start_dht();
    g_session->start_lsd();
    g_session->start_upnp();
    g_session->start_natpmp();
    return reinterpret_cast<jlong>(g_session);
}

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeDestroySession(
    JNIEnv* env, jobject thiz, jlong ptr) {
    if (g_session) {
        g_session->pause();
        g_session->stop_dht();
        g_session->stop_lsd();
        g_session->stop_upnp();
        g_session->stop_natpmp();
        delete g_session;
        g_session = nullptr;
    }
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeAddTorrent(
    JNIEnv* env, jobject thiz, jlong ptr, jstring j_source) {
    if (!g_session) return env->NewStringUTF("");

    const char* c_source = env->GetStringUTFChars(j_source, nullptr);
    std::string source(c_source);
    env->ReleaseStringUTFChars(j_source, c_source);

    lt::add_torrent_params params;
    lt::error_code ec;

    if (source.find("magnet:") == 0) {
        params = lt::parse_magnet_uri(source, ec);
    } else if (source.find("http://") == 0 || source.find("https://") == 0) {
        params.url = source;
    } else {
        params.ti = std::make_shared<lt::torrent_info>(source, ec);
    }

    if (ec) {
        return env->NewStringUTF(ec.message().c_str());
    }

    params.save_path = "/storage/emulated/0/Download/Getzy";
    params.flags &= ~lt::torrent_flags::paused;
    params.flags &= ~lt::torrent_flags::auto_managed;

    lt::torrent_handle handle = g_session->add_torrent(params, ec);
    if (ec) {
        return env->NewStringUTF(ec.message().c_str());
    }

    std::string info_hash = lt::to_hex(handle.info_hash().to_string());

    // Set sequential download if requested
    // handle.set_sequential_download(true);

    // Set file priorities if needed
    // std::vector<lt::download_priority_t> priorities;
    // handle.set_file_priorities(priorities);

    return env->NewStringUTF(info_hash.c_str());
}

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeRemoveTorrent(
    JNIEnv* env, jobject thiz, jlong ptr, jstring j_info_hash) {
    if (!g_session) return;
    const char* c_hash = env->GetStringUTFChars(j_info_hash, nullptr);
    lt::sha1_hash hash;
    lt::from_hex(c_hash, 40, (char*)hash.data());
    env->ReleaseStringUTFChars(j_info_hash, c_hash);

    std::vector<lt::torrent_handle> handles = g_session->get_torrents();
    for (auto& h : handles) {
        if (h.info_hash() == hash) {
            g_session->remove_torrent(h, lt::session::delete_files);
            break;
        }
    }
}

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativePauseTorrent(
    JNIEnv* env, jobject thiz, jlong ptr, jstring j_info_hash) {
    if (!g_session) return;
    const char* c_hash = env->GetStringUTFChars(j_info_hash, nullptr);
    lt::sha1_hash hash;
    lt::from_hex(c_hash, 40, (char*)hash.data());
    env->ReleaseStringUTFChars(j_info_hash, c_hash);

    std::vector<lt::torrent_handle> handles = g_session->get_torrents();
    for (auto& h : handles) {
        if (h.info_hash() == hash) {
            h.pause();
            break;
        }
    }
}

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeResumeTorrent(
    JNIEnv* env, jobject thiz, jlong ptr, jstring j_info_hash) {
    if (!g_session) return;
    const char* c_hash = env->GetStringUTFChars(j_info_hash, nullptr);
    lt::sha1_hash hash;
    lt::from_hex(c_hash, 40, (char*)hash.data());
    env->ReleaseStringUTFChars(j_info_hash, c_hash);

    std::vector<lt::torrent_handle> handles = g_session->get_torrents();
    for (auto& h : handles) {
        if (h.info_hash() == hash) {
            h.resume();
            break;
        }
    }
}

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativePauseAll(
    JNIEnv* env, jobject thiz, jlong ptr) {
    if (!g_session) return;
    g_session->pause();
}

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeResumeAll(
    JNIEnv* env, jobject thiz, jlong ptr) {
    if (!g_session) return;
    g_session->resume();
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeGetTorrentStatuses(
    JNIEnv* env, jobject thiz, jlong ptr) {
    if (!g_session) {
        return env->NewObjectArray(0, env->FindClass("java/lang/String"), nullptr);
    }

    std::vector<lt::torrent_handle> handles = g_session->get_torrents();
    jclass stringClass = env->FindClass("java/lang/String");
    jobjectArray result = env->NewObjectArray(handles.size(), stringClass, nullptr);

    for (size_t i = 0; i < handles.size(); i++) {
        if (!handles[i].is_valid()) continue;
        lt::torrent_status status = handles[i].status();

        char buffer[1024];
        snprintf(buffer, sizeof(buffer),
            "{\"info_hash\":\"%s\",\"name\":\"%s\",\"status\":\"%s\","
            "\"progress\":%f,\"downloaded_bytes\":%ld,\"total_bytes\":%ld,"
            "\"download_speed\":%d,\"upload_speed\":%d,\"eta\":%ld}",
            lt::to_hex(status.info_hash.to_string()).c_str(),
            status.name.c_str(),
            status.state == lt::torrent_status::downloading ? "downloading" :
            status.state == lt::torrent_status::seeding ? "seeding" :
            status.state == lt::torrent_status::finished ? "finished" :
            status.state == lt::torrent_status::paused ? "paused" :
            status.state == lt::torrent_status::checking_files ? "checking" :
            status.state == lt::torrent_status::queued_for_checking ? "queued" : "unknown",
            status.progress,
            (long)status.total_download,
            (long)status.total_wanted,
            (int)status.download_rate,
            (int)status.upload_rate,
            (long)status.next_expected_dht_download.seconds()
        );

        env->SetObjectArrayElement(result, i, env->NewStringUTF(buffer));
    }

    return result;
}

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeApplySettings(
    JNIEnv* env, jobject thiz, jlong ptr, jstring j_settings_json) {
    if (!g_session) return;

    const char* c_json = env->GetStringUTFChars(j_settings_json, nullptr);
    std::string json(c_json);
    env->ReleaseStringUTFChars(j_settings_json, c_json);

    lt::settings_pack pack;

    // Parse JSON and apply settings
    // For now, use hardcoded defaults
    pack.set_int(lt::settings_pack::download_rate_limit, 0);
    pack.set_int(lt::settings_pack::upload_rate_limit, 0);
    pack.set_int(lt::settings_pack::connections_limit, 200);
    pack.set_bool(lt::settings_pack::enable_outgoing_utp, true);
    pack.set_bool(lt::settings_pack::enable_incoming_utp, true);
    pack.set_int(lt::settings_pack::proxy_type, lt::settings_pack::proxy_type_t::none);

    g_session->apply_settings(pack);
}
