#include <jni.h>
#include <string>
#include <vector>
#include <map>
#include <set>
#include <cstring>
#include <cstdio>

#include <libtorrent/session.hpp>
#include <libtorrent/add_torrent_params.hpp>
#include <libtorrent/torrent_handle.hpp>
#include <libtorrent/torrent_status.hpp>
#include <libtorrent/alert_types.hpp>
#include <libtorrent/settings_pack.hpp>
#include <libtorrent/error_code.hpp>
#include <libtorrent/magnet_uri.hpp>
#include <libtorrent/announce_entry.hpp>
#include <libtorrent/torrent_info.hpp>
#include <libtorrent/file_storage.hpp>
#include <libtorrent/download_priority.hpp>
#include <libtorrent/hex.hpp>
#include <libtorrent/info_hash.hpp>

static lt::session* g_session = nullptr;
static JavaVM* g_jvm = nullptr;
static std::string g_save_path = "";

static std::string jsonEscape(const std::string& raw) {
    std::string out;
    out.reserve(raw.size() + 16);
    for (size_t i = 0; i < raw.size(); i++) {
        char c = raw[i];
        switch (c) {
            case '\"': out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\n': out += "\\n"; break;
            case '\r': out += "\\r"; break;
            case '\t': out += "\\t"; break;
            default: out += c;
        }
    }
    return out;
}

// Minimal JSON string value extractor (no external deps needed)
static std::string jsonExtractString(const std::string& json, const std::string& key) {
    std::string search = "\"" + key + "\":\"";
    auto pos = json.find(search);
    if (pos == std::string::npos) return "";
    pos += search.length();
    std::string result;
    while (pos < json.length() && json[pos] != '\"') {
        if (json[pos] == '\\' && pos + 1 < json.length()) {
            if (json[pos + 1] == '\"') { result += '\"'; pos += 2; continue; }
            if (json[pos + 1] == '\\') { result += '\\'; pos += 2; continue; }
            if (json[pos + 1] == 'n') { result += '\n'; pos += 2; continue; }
        }
        result += json[pos++];
    }
    return result;
}

static int jsonExtractInt(const std::string& json, const std::string& key, int defaultVal = 0) {
    std::string search = "\"" + key + "\":";
    auto pos = json.find(search);
    if (pos == std::string::npos) return defaultVal;
    pos += search.length();
    while (pos < json.length() && (json[pos] == ' ' || json[pos] == '\t')) pos++;
    bool negative = false;
    if (pos < json.length() && json[pos] == '-') { negative = true; pos++; }
    int val = 0;
    while (pos < json.length() && json[pos] >= '0' && json[pos] <= '9') {
        val = val * 10 + (json[pos] - '0');
        pos++;
    }
    return negative ? -val : val;
}

static bool jsonExtractBool(const std::string& json, const std::string& key, bool defaultVal = false) {
    std::string search = "\"" + key + "\":";
    auto pos = json.find(search);
    if (pos == std::string::npos) return defaultVal;
    pos += search.length();
    while (pos < json.length() && (json[pos] == ' ' || json[pos] == '\t')) pos++;
    if (json.substr(pos, 4) == "true") return true;
    if (json.substr(pos, 5) == "false") return false;
    return defaultVal;
}

extern "C" JNIEXPORT jint JNICALL
JNI_OnLoad(JavaVM* vm, void* reserved) {
    g_jvm = vm;
    return JNI_VERSION_1_6;
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeCreateSession(
    JNIEnv* env, jobject thiz, jstring j_save_path) {
    if (g_session) {
        delete g_session;
    }

    if (j_save_path != nullptr) {
        const char* c_path = env->GetStringUTFChars(j_save_path, nullptr);
        g_save_path = std::string(c_path);
        env->ReleaseStringUTFChars(j_save_path, c_path);
    }
    if (g_save_path.empty()) {
        g_save_path = "/data/data/com.getzy.getzy/files/Getzy";
    }

    lt::settings_pack pack;
    pack.set_int(lt::settings_pack::alert_mask, lt::alert::status_notification |
        lt::alert::error_notification);
    pack.set_bool(lt::settings_pack::enable_dht, true);
    pack.set_bool(lt::settings_pack::enable_lsd, true);
    pack.set_bool(lt::settings_pack::enable_upnp, true);
    pack.set_bool(lt::settings_pack::enable_natpmp, true);
    g_session = new lt::session(pack);
    return reinterpret_cast<jlong>(g_session);
}

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeDestroySession(
    JNIEnv* env, jobject thiz, jlong ptr) {
    if (g_session) {
        g_session->pause();
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
        return env->NewStringUTF("");
    }

    params.save_path = g_save_path;
    params.flags &= ~lt::torrent_flags::paused;
    params.flags &= ~lt::torrent_flags::auto_managed;

    lt::torrent_handle handle = g_session->add_torrent(params, ec);
    if (ec) {
        return env->NewStringUTF("");
    }

    auto ih = handle.info_hashes();
    std::string info_hash;
    if (ih.has_v1()) {
        info_hash = lt::aux::to_hex(ih.v1.to_string());
    } else if (ih.has_v2()) {
        info_hash = lt::aux::to_hex(ih.v2.to_string());
    }

    return env->NewStringUTF(info_hash.c_str());
}

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeRemoveTorrent(
    JNIEnv* env, jobject thiz, jlong ptr, jstring j_info_hash) {
    if (!g_session) return;
    const char* c_hash = env->GetStringUTFChars(j_info_hash, nullptr);
    std::string target_hash(c_hash);
    env->ReleaseStringUTFChars(j_info_hash, c_hash);

    std::vector<lt::torrent_handle> handles = g_session->get_torrents();
    for (auto& h : handles) {
        auto ih = h.info_hashes();
        std::string hh;
        if (ih.has_v1()) hh = lt::aux::to_hex(ih.v1.to_string());
        else if (ih.has_v2()) hh = lt::aux::to_hex(ih.v2.to_string());
        if (hh == target_hash) {
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
    std::string target_hash(c_hash);
    env->ReleaseStringUTFChars(j_info_hash, c_hash);

    std::vector<lt::torrent_handle> handles = g_session->get_torrents();
    for (auto& h : handles) {
        auto ih = h.info_hashes();
        std::string hh;
        if (ih.has_v1()) hh = lt::aux::to_hex(ih.v1.to_string());
        else if (ih.has_v2()) hh = lt::aux::to_hex(ih.v2.to_string());
        if (hh == target_hash) {
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
    std::string target_hash(c_hash);
    env->ReleaseStringUTFChars(j_info_hash, c_hash);

    std::vector<lt::torrent_handle> handles = g_session->get_torrents();
    for (auto& h : handles) {
        auto ih = h.info_hashes();
        std::string hh;
        if (ih.has_v1()) hh = lt::aux::to_hex(ih.v1.to_string());
        else if (ih.has_v2()) hh = lt::aux::to_hex(ih.v2.to_string());
        if (hh == target_hash) {
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

        long eta_seconds = -1;
        if (status.state == lt::torrent_status::state_t::downloading && status.download_rate > 0) {
            long remaining = status.total_wanted - status.total_wanted_done;
            if (remaining > 0) {
                eta_seconds = remaining / status.download_rate;
            }
        }

        const char* status_str = "unknown";
        if (status.paused) {
            status_str = "paused";
        } else {
            switch (status.state) {
                case lt::torrent_status::state_t::downloading: status_str = "downloading"; break;
                case lt::torrent_status::state_t::seeding: status_str = "seeding"; break;
                case lt::torrent_status::state_t::finished: status_str = "finished"; break;
                case lt::torrent_status::state_t::checking_files: status_str = "checking"; break;
                case lt::torrent_status::state_t::downloading_metadata: status_str = "downloading"; break;
                default: status_str = "queued";
            }
        }

        char buffer[1536];
        auto ih = handles[i].info_hashes();
        std::string info_hash_str;
        if (ih.has_v1()) info_hash_str = lt::aux::to_hex(ih.v1.to_string());
        else if (ih.has_v2()) info_hash_str = lt::aux::to_hex(ih.v2.to_string());

        std::string escaped_name = jsonEscape(status.name);
        snprintf(buffer, sizeof(buffer),
            "{"
            "\"info_hash\":\"%s\","
            "\"name\":\"%s\","
            "\"status\":\"%s\","
            "\"progress\":%f,"
            "\"downloaded_bytes\":%ld,"
            "\"total_bytes\":%ld,"
            "\"download_speed\":%d,"
            "\"upload_speed\":%d,"
            "\"eta\":%ld,"
            "\"num_peers\":%d,"
            "\"num_seeds\":%d,"
            "\"queue_position\":%d"
            "}",
            info_hash_str.c_str(),
            escaped_name.c_str(),
            status_str,
            status.progress,
            (long)status.total_download,
            (long)status.total_wanted,
            (int)status.download_rate,
            (int)status.upload_rate,
            eta_seconds,
            (int)status.num_peers,
            (int)status.num_seeds,
            static_cast<int>(status.queue_position)
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

    // Bandwidth
    int dl = jsonExtractInt(json, "max_download_speed", 0);
    int ul = jsonExtractInt(json, "max_upload_speed", 0);
    int conns = jsonExtractInt(json, "max_connections", 200);
    pack.set_int(lt::settings_pack::download_rate_limit, dl * 1024);
    pack.set_int(lt::settings_pack::upload_rate_limit, ul * 1024);
    pack.set_int(lt::settings_pack::connections_limit, conns);

    // Protocol toggles
    bool dht = jsonExtractBool(json, "enable_dht", true);
    bool lsd = jsonExtractBool(json, "enable_lsd", true);
    bool upnp = jsonExtractBool(json, "enable_upnp", true);
    bool natpmp = jsonExtractBool(json, "enable_nat_pmp", true);
    bool pex = jsonExtractBool(json, "enable_pex", true);
    bool utp = jsonExtractBool(json, "enable_utp", true);
    bool random_port = jsonExtractBool(json, "random_port", true);
    int port = jsonExtractInt(json, "listening_port", 55623);

    pack.set_bool(lt::settings_pack::enable_outgoing_utp, utp);
    pack.set_bool(lt::settings_pack::enable_incoming_utp, utp);
    pack.set_bool(lt::settings_pack::enable_dht, dht);
    pack.set_bool(lt::settings_pack::enable_lsd, lsd);
    pack.set_bool(lt::settings_pack::enable_upnp, upnp);
    pack.set_bool(lt::settings_pack::enable_natpmp, natpmp);
    pack.set_int(lt::settings_pack::max_out_request_queue, pex ? 500 : 50);

    if (random_port) {
        pack.set_str(lt::settings_pack::listen_interfaces, "0.0.0.0:0,[::]:0");
    } else {
        char iface[64];
        snprintf(iface, sizeof(iface), "0.0.0.0:%d,[::]:%d", port, port);
        pack.set_str(lt::settings_pack::listen_interfaces, iface);
    }

    // Encryption (libtorrent 2.0 settings_pack API)
    std::string enc_in = jsonExtractString(json, "encryption_incoming");
    std::string enc_out = jsonExtractString(json, "encryption_outgoing");
    std::string enc_level = jsonExtractString(json, "encryption_level");
    if (enc_level == "forced") {
        pack.set_int(lt::settings_pack::in_enc_policy, lt::settings_pack::pe_forced);
        pack.set_int(lt::settings_pack::out_enc_policy, lt::settings_pack::pe_forced);
    } else if (enc_level == "enabled" || enc_level.empty()) {
        pack.set_int(lt::settings_pack::in_enc_policy, lt::settings_pack::pe_enabled);
        pack.set_int(lt::settings_pack::out_enc_policy, lt::settings_pack::pe_enabled);
    } else {
        pack.set_int(lt::settings_pack::in_enc_policy, lt::settings_pack::pe_disabled);
        pack.set_int(lt::settings_pack::out_enc_policy, lt::settings_pack::pe_disabled);
    }
    if (!enc_in.empty()) {
        pack.set_int(lt::settings_pack::in_enc_policy,
            enc_in == "forced" ? lt::settings_pack::pe_forced :
            enc_in == "enabled" ? lt::settings_pack::pe_enabled :
            lt::settings_pack::pe_disabled);
    }
    if (!enc_out.empty()) {
        pack.set_int(lt::settings_pack::out_enc_policy,
            enc_out == "forced" ? lt::settings_pack::pe_forced :
            enc_out == "enabled" ? lt::settings_pack::pe_enabled :
            lt::settings_pack::pe_disabled);
    }

    // Proxy
    std::string proxy_type = jsonExtractString(json, "proxy_type");
    if (!proxy_type.empty() && proxy_type != "none") {
        std::string proxy_host = jsonExtractString(json, "proxy_host");
        int proxy_port = jsonExtractInt(json, "proxy_port", 0);
        std::string proxy_user = jsonExtractString(json, "proxy_username");
        std::string proxy_pass = jsonExtractString(json, "proxy_password");
        if (proxy_type == "socks4") pack.set_int(lt::settings_pack::proxy_type, lt::settings_pack::socks4);
        else if (proxy_type == "socks5") pack.set_int(lt::settings_pack::proxy_type, lt::settings_pack::socks5);
        else if (proxy_type == "http" || proxy_type == "https") pack.set_int(lt::settings_pack::proxy_type, lt::settings_pack::http);
        else pack.set_int(lt::settings_pack::proxy_type, lt::settings_pack::none);
        pack.set_str(lt::settings_pack::proxy_hostname, proxy_host);
        pack.set_int(lt::settings_pack::proxy_port, proxy_port);
        if (!proxy_user.empty()) pack.set_str(lt::settings_pack::proxy_username, proxy_user);
        if (!proxy_pass.empty()) pack.set_str(lt::settings_pack::proxy_password, proxy_pass);
    } else {
        pack.set_int(lt::settings_pack::proxy_type, lt::settings_pack::none);
    }

    // Storage path
    std::string storage_path = jsonExtractString(json, "storage_path");
    if (!storage_path.empty()) {
        g_save_path = storage_path;
    }

    g_session->apply_settings(pack);
}

extern "C" JNIEXPORT void JNICALL
Java_com_getzy_getzy_TorrentBridge_nativeSetFilePriorities(
    JNIEnv* env, jobject thiz, jlong ptr, jstring j_info_hash,
    jobjectArray j_selected_files) {
    if (!g_session) return;

    const char* c_hash = env->GetStringUTFChars(j_info_hash, nullptr);
    std::string target_hash(c_hash);
    env->ReleaseStringUTFChars(j_info_hash, c_hash);

    jsize selectedCount = env->GetArrayLength(j_selected_files);

    std::vector<lt::torrent_handle> handles = g_session->get_torrents();
    for (auto& h : handles) {
        if (!h.is_valid()) continue;
        auto ih = h.info_hashes();
        std::string hh;
        if (ih.has_v1()) hh = lt::aux::to_hex(ih.v1.to_string());
        else if (ih.has_v2()) hh = lt::aux::to_hex(ih.v2.to_string());
        if (hh != target_hash) continue;

        if (!h.torrent_file()) {
            // Metadata not yet resolved
            return;
        }

        int numFiles = h.torrent_file()->num_files();
        std::vector<lt::download_priority_t> priorities(
            numFiles, lt::dont_download);

        // Build set of selected file paths
        std::set<std::string> selectedPaths;
        for (jsize i = 0; i < selectedCount; i++) {
            jstring j_path = (jstring)env->GetObjectArrayElement(j_selected_files, i);
            const char* c_path = env->GetStringUTFChars(j_path, nullptr);
            selectedPaths.insert(std::string(c_path));
            env->ReleaseStringUTFChars(j_path, c_path);
        }

        // Set priority 4 (default) for selected files, 0 for others
        lt::file_storage const& fs = h.torrent_file()->files();
        for (int fi = 0; fi < numFiles; fi++) {
            std::string fp = fs.file_path(fi);
            if (selectedPaths.find(fp) != selectedPaths.end()) {
                priorities[fi] = lt::default_priority;
            }
        }

        for (int fi = 0; fi < numFiles; fi++) {
            h.file_priority(lt::file_index_t{fi}, priorities[fi]);
        }
        break;
    }
}
