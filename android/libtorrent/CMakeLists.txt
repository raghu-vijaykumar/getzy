cmake_minimum_required(VERSION 3.18.1)

project("torrent_bridge")

set(LIBTORRENT_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/jni)
set(LIBTORRENT_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include)
set(LIBTORRENT_LIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/prebuilt/${ANDROID_ABI})

# Set this to the Boost headers root, or pass -DBOOST_ROOT via Gradle
if(NOT BOOST_ROOT)
    set(BOOST_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../external/boost)
endif()

add_library(torrent_bridge SHARED
    ${LIBTORRENT_SRC_DIR}/torrent_bridge.cpp
)

target_include_directories(torrent_bridge PRIVATE
    ${LIBTORRENT_INCLUDE_DIR}
    ${BOOST_ROOT}
)

target_link_directories(torrent_bridge PRIVATE
    ${LIBTORRENT_LIB_DIR}
)

target_link_libraries(torrent_bridge
    torrent-rasterbar
    log
)

target_compile_options(torrent_bridge PRIVATE
    -std=c++17
    -fexceptions
    -frtti
)
