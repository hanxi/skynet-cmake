cmake_minimum_required(VERSION 3.10)

project(skynet)

# 添加编译选项
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 把lua头文件添加到全局搜索路径
include_directories(skynet/3rd/lua/
                    3rd/core/sol/include/
                    3rd/core/common/ )

# Linux
if (CMAKE_SYSTEM_NAME MATCHES "Linux")
    message(STATUS "current platform: Linux")
    add_compile_definitions(NOUSE_JEMALLOC LUA_USE_LINUX LUA_USE_READLINE)

    # 添加编译选项
    add_compile_options(-g)

    # 编译 skynet 可执行文件
    aux_source_directory(skynet/skynet-src SKYNET_SRC)
    aux_source_directory(skynet/3rd/lua LUA_LIB_SRC)
    list(REMOVE_ITEM LUA_LIB_SRC "skynet/3rd/lua/lua.c" "skynet/3rd/lua/luac.c" "skynet/3rd/lua/onelua.c")
    message(STATUS "The value of LUA_LIB_SRC is: ${LUA_LIB_SRC}")
    message(STATUS "The value of SKYNET_SRC is: ${SKYNET_SRC}")
    add_executable(skynet ${SKYNET_SRC} ${LUA_LIB_SRC})
    target_include_directories(skynet PRIVATE skynet/skynet-src)
    target_link_options(skynet PRIVATE "LINKER:-E")
    target_link_libraries(skynet m pthread dl rt)

    message(STATUS "The value of CMAKE_BINARY_DIR is: ${CMAKE_BINARY_DIR}")

    # 重新设置动态库输出路径
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/cservice)

    # 生成c服务
    file(GLOB CSERVICE_FILE_LIST "skynet/service-src/*.c")
    message(STATUS "The value of CSERVICE_FILE_LIST is: ${CSERVICE_FILE_LIST}")
    foreach(FILE_PATH IN LISTS CSERVICE_FILE_LIST)
        message(STATUS "Processing file: ${FILE_PATH}")
        string(REGEX REPLACE ".*skynet/service-src/service_" "" LIB_NAME "${FILE_PATH}")
        string(REGEX REPLACE ".c$" "" LIB_NAME "${LIB_NAME}")
        message(STATUS "The value of LIB_NAME is: ${LIB_NAME}")
        add_library(${LIB_NAME} SHARED ${FILE_PATH})
        target_include_directories(${LIB_NAME} PRIVATE skynet/skynet-src)
        set_target_properties(${LIB_NAME} PROPERTIES PREFIX "")
    endforeach()

    # 重新设置动态库输出路径
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/luaclib)

    # 生成动态库 skynet.so
    set(LUA_CLIB_SKYNET_SRC
        skynet/lualib-src/lua-skynet.c
        skynet/lualib-src/lua-seri.c
        skynet/lualib-src/lua-socket.c
        skynet/lualib-src/lua-mongo.c
        skynet/lualib-src/lua-netpack.c
        skynet/lualib-src/lua-memory.c
        skynet/lualib-src/lua-multicast.c
        skynet/lualib-src/lua-cluster.c
        skynet/lualib-src/lua-crypt.c
        skynet/lualib-src/lsha1.c
        skynet/lualib-src/lua-sharedata.c
        skynet/lualib-src/lua-stm.c
        skynet/lualib-src/lua-debugchannel.c
        skynet/lualib-src/lua-datasheet.c
        skynet/lualib-src/lua-sharetable.c )
    add_library(skynetso SHARED ${LUA_CLIB_SKYNET_SRC})
    target_include_directories(skynetso PRIVATE skynet/skynet-src skynet/lualib-src)
    set_target_properties(skynetso PROPERTIES OUTPUT_NAME skynet)
    set_target_properties(skynetso PROPERTIES PREFIX "")

    # 生成动态库 bson.so
    add_library(bson SHARED skynet/lualib-src/lua-bson.c)
    target_include_directories(bson PRIVATE skynet/skynet-src)

    # 生成动态库 md5.so
    aux_source_directory(skynet/3rd/lua-md5 LUA_MD5_SRC)
    add_library(md5 SHARED ${LUA_MD5_SRC})

    # 生成动态库 client.so
    add_library(client SHARED skynet/lualib-src/lua-clientsocket.c
                    skynet/lualib-src/lua-crypt.c
                    skynet/lualib-src/lsha1.c)
    target_link_libraries(client pthread)

    # 生成动态库 sproto.so
    aux_source_directory(skynet/lualib-src/sproto SPROTO_SRC)
    add_library(sproto SHARED ${SPROTO_SRC})

    # 生成动态库 lpeg.so
    aux_source_directory(skynet/3rd/lpeg LPEG_SRC)
    add_library(lpeg SHARED ${LPEG_SRC})

    # 生成动态库 ltls.so
    add_library(ltls SHARED skynet/lualib-src/ltls.c)
    target_include_directories(ltls PRIVATE 3rd/core/openssl/include/)
    target_link_directories(ltls PRIVATE 3rd/core/openssl/lib/linux/)
    target_link_libraries(ltls ssl crypto)

    # 生成动态库 pb.so
    aux_source_directory(3rd/luaclib/lua-protobuf PB_SRC)
    add_library(pb SHARED ${PB_SRC})

    # 生成动态库 lfs.so
    aux_source_directory(3rd/luaclib/luafilesystem LFS_SRC)
    add_library(lfs SHARED ${LFS_SRC})

    # 生成动态库 fmt.so
    aux_source_directory(3rd/luaclib/lua-fmt FMT_SRC)
    add_library(fmt SHARED ${FMT_SRC})

    # 生成动态库 yyjson.so
    aux_source_directory(3rd/luaclib/lua-yyjson YYJSON_SRC)
    add_library(yyjson SHARED ${YYJSON_SRC})

    # 生成动态库 zset.so
    aux_source_directory(3rd/luaclib/lua-zset ZSET_SRC)
    add_library(zset SHARED ${ZSET_SRC})

    # 生成动态库 aoi.so
    aux_source_directory(3rd/luaclib/lua-aoi AOI_SRC)
    add_library(aoi SHARED ${AOI_SRC})

    # 生成动态库 navmesh.so
    aux_source_directory(3rd/luaclib/lua-navmesh NAVMESH_SRC)
    aux_source_directory(3rd/core/recastnavigation/Detour/Source Detour_SRC)
    aux_source_directory(3rd/core/recastnavigation/DetourCrowd/Source DetourCrowd_SRC)
    aux_source_directory(3rd/core/recastnavigation/DetourTileCache/Source DetourTileCache_SRC)
    aux_source_directory(3rd/core/recastnavigation/Recast/Source Recast_SRC)
    add_library(navmesh SHARED ${NAVMESH_SRC} 
                            ${Detour_SRC} ${DetourCrowd_SRC}
                            ${DetourTileCache_SRC} ${Recast_SRC})
    target_include_directories(navmesh PRIVATE 
                        3rd/core/recastnavigation/Detour/Include/
                        3rd/core/recastnavigation/DetourCrowd/Include/
                        3rd/core/recastnavigation/DetourTileCache/Include/
                        3rd/core/recastnavigation/Recast/Include/)

    # 生成动态库 math3d.so
    aux_source_directory(3rd/luaclib/math3d MATH3D_SRC)
    add_library(math3d SHARED ${MATH3D_SRC})
    target_include_directories(math3d PRIVATE 3rd/core/glm/include/)
    target_compile_definitions(math3d PUBLIC -DGLM_ENABLE_EXPERIMENTAL -DGLM_FORCE_QUAT_DATA_XYZW)

    # 生成动态库 rp3d.so
    aux_source_directory(3rd/luaclib/lua-rp3d RP3D_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/body/ RP3D_body_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/ RP3D_collision_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/broadphase/ RP3D_collision_broadphase_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/narrowphase/ RP3D_collision_narrowphase_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/narrowphase/GJK/ RP3D_collision_narrowphase_GJK_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/narrowphase/SAT/ RP3D_collision_narrowphase_SAT_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/shapes/ RP3D_collision_shapes_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/components/ RP3D_components_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/constraint/ RP3D_constraint_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/engine/ RP3D_engine_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/mathematics/ RP3D_mathematics_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/memory/ RP3D_memory_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/systems/ RP3D_systems_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/utils/ RP3D_utils_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/utils/quickhull/ RP3D_utils_quickhull_SRC)
    add_library(rp3d SHARED ${RP3D_SRC} ${RP3D_body_SRC} 
                ${RP3D_collision_SRC}  ${RP3D_collision_broadphase_SRC}
                ${RP3D_collision_narrowphase_SRC} ${RP3D_collision_narrowphase_GJK_SRC}
                ${RP3D_collision_narrowphase_SAT_SRC} ${RP3D_collision_shapes_SRC}
                ${RP3D_components_SRC} ${RP3D_constraint_SRC}
                ${RP3D_engine_SRC} ${RP3D_mathematics_SRC}
                ${RP3D_memory_SRC} ${RP3D_systems_SRC}
                ${RP3D_utils_SRC} ${RP3D_utils_quickhull_SRC} )
    target_include_directories(rp3d PRIVATE 3rd/core/reactphysics3d/include/
                3rd/core/reactphysics3d/include/reactphysics3d/body/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/broadphase/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/narrowphase/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/narrowphase/GJK/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/narrowphase/SAT/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/shapes/
                3rd/core/reactphysics3d/include/reactphysics3d/components/
                3rd/core/reactphysics3d/include/reactphysics3d/constraint/
                3rd/core/reactphysics3d/include/reactphysics3d/containers/
                3rd/core/reactphysics3d/include/reactphysics3d/engine/
                3rd/core/reactphysics3d/include/reactphysics3d/mathematics/
                3rd/core/reactphysics3d/include/reactphysics3d/memory/
                3rd/core/reactphysics3d/include/reactphysics3d/systems/
                3rd/core/reactphysics3d/include/reactphysics3d/utils/
                3rd/core/reactphysics3d/include/reactphysics3d/utils/quickhull/ )

    # 生成动态库 logrus.so
    aux_source_directory(3rd/luaclib/lua-logrus LOGRUS_SRC)
    add_library(logrus SHARED ${LOGRUS_SRC})
    target_include_directories(logrus PRIVATE 3rd/core/spdlog/include/)
    target_link_libraries(logrus m pthread dl)

    set_target_properties(lpeg sproto client md5 bson ltls
        pb lfs fmt yyjson  
        zset aoi navmesh math3d 
        rp3d logrus
        PROPERTIES
        PREFIX ""
        SUFFIX .so
    )
endif ()

# Windows
if (CMAKE_SYSTEM_NAME MATCHES "Windows")
    message(STATUS "current platform: Windows")
    add_compile_definitions(NOUSE_JEMALLOC LUA_BUILD_AS_DLL)

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-int-conversion -Wno-implicit-function-declaration -Wno-deprecated-declarations")
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

    # 把lua头文件添加到全局搜索路径
    include_directories(3rd/core/posix 3rd/pthread-win32 skynet/skynet-src)
    add_compile_options(/FI ${CMAKE_SOURCE_DIR}/3rd/core/posix/unistd.h)

    message(STATUS "The value of CMAKE_BINARY_DIR is: ${CMAKE_BINARY_DIR}")

    aux_source_directory(skynet/skynet-src LIB_SKYNET_SRC)
    list(REMOVE_ITEM LIB_SKYNET_SRC skynet/skynet-src/skynet_main.c)
    aux_source_directory(skynet/3rd/lua LUA_LIB_SRC)
    list(REMOVE_ITEM LUA_LIB_SRC "skynet/3rd/lua/lua.c" "skynet/3rd/lua/luac.c" "skynet/3rd/lua/onelua.c")
    aux_source_directory(3rd/core/posix POSIX_SRC)

    add_subdirectory(3rd/pthread-win32)

    message(STATUS "The value of LUA_LIB_SRC is: ${LUA_LIB_SRC}")
    add_library(liblua SHARED ${LUA_LIB_SRC})
    add_library(libposix SHARED ${POSIX_SRC})
    target_link_libraries(libposix ws2_32)
    add_library(libskynet SHARED ${LIB_SKYNET_SRC})
    target_link_libraries(libskynet liblua libposix pthreadVC3)

    # 编译 skynet 可执行文件
    add_executable(skynet skynet/skynet-src/skynet_main.c)
    target_link_libraries(skynet ws2_32 liblua libposix libskynet pthreadVC3)

    # 生成动态库 skynet.so
    set(LUA_CLIB_SKYNET_SRC
        skynet/lualib-src/lua-skynet.c
        skynet/lualib-src/lua-seri.c
        skynet/lualib-src/lua-socket.c
        skynet/lualib-src/lua-mongo.c
        skynet/lualib-src/lua-netpack.c
        skynet/lualib-src/lua-memory.c
        skynet/lualib-src/lua-multicast.c
        skynet/lualib-src/lua-cluster.c
        skynet/lualib-src/lua-crypt.c
        skynet/lualib-src/lsha1.c
        skynet/lualib-src/lua-sharedata.c
        skynet/lualib-src/lua-stm.c
        skynet/lualib-src/lua-debugchannel.c
        skynet/lualib-src/lua-datasheet.c
        skynet/lualib-src/lua-sharetable.c )
    message(STATUS "The value of LIB_SKYNET_SRC is: ${LIB_SKYNET_SRC}")
    add_library(skynetso SHARED ${LUA_CLIB_SKYNET_SRC})
    target_compile_definitions(skynetso PUBLIC LUA_LIB)
    set_target_properties(skynetso PROPERTIES OUTPUT_NAME skynet)
    target_link_libraries(skynetso ws2_32 libskynet)

    # 生成动态库 bson.so
    add_library(bson SHARED skynet/lualib-src/lua-bson.c)
    target_link_libraries(bson ws2_32 liblua)

    # 生成动态库 md5.so
    aux_source_directory(skynet/3rd/lua-md5 LUA_MD5_SRC)
    add_library(md5 SHARED ${LUA_MD5_SRC})
    target_link_libraries(md5 liblua)

    # 生成动态库 client.so
    add_library(client SHARED skynet/lualib-src/lua-clientsocket.c
                        skynet/lualib-src/lua-crypt.c
                        skynet/lualib-src/lsha1.c)
    target_link_libraries(client ws2_32 liblua libposix pthreadVC3)

    # 生成动态库 sproto.so
    aux_source_directory(skynet/lualib-src/sproto SPROTO_SRC)
    add_library(sproto SHARED ${SPROTO_SRC})
    target_link_libraries(sproto liblua)

    # 生成动态库 lpeg.so
    aux_source_directory(skynet/3rd/lpeg LPEG_SRC)
    add_library(lpeg SHARED ${LPEG_SRC})
    target_link_libraries(lpeg liblua)

    # # 生成动态库 ltls.so
    # add_library(ltls SHARED skynet/lualib-src/ltls.c)
    # target_include_directories(ltls PRIVATE 3rd/core/openssl/include/)
    # target_link_directories(ltls PRIVATE 3rd/core/openssl/lib/windows/)
    # target_link_libraries(ltls liblua libssl libcrypto)

    # 生成动态库 pb.so
    aux_source_directory(3rd/luaclib/lua-protobuf PB_SRC)
    add_library(pb SHARED ${PB_SRC})
    target_link_libraries(pb liblua)

    # 生成动态库 lfs.so
    aux_source_directory(3rd/luaclib/luafilesystem LFS_SRC)
    add_library(lfs SHARED ${LFS_SRC})
    target_link_libraries(lfs liblua)

    # 生成动态库 fmt.so
    aux_source_directory(3rd/luaclib/lua-fmt FMT_SRC)
    add_library(fmt SHARED ${FMT_SRC})
    target_link_libraries(fmt liblua)

    # 生成动态库 yyjson.so
    aux_source_directory(3rd/luaclib/lua-yyjson YYJSON_SRC)
    add_library(yyjson SHARED ${YYJSON_SRC})
    target_link_libraries(yyjson liblua)

    # 生成动态库 zset.so
    aux_source_directory(3rd/luaclib/lua-zset ZSET_SRC)
    add_library(zset SHARED ${ZSET_SRC})
    target_link_libraries(zset liblua)

    # 生成动态库 aoi.so
    aux_source_directory(3rd/luaclib/lua-aoi AOI_SRC)
    add_library(aoi SHARED ${AOI_SRC})
    target_link_libraries(aoi liblua)

    # 生成动态库 navmesh.so
    aux_source_directory(3rd/luaclib/lua-navmesh NAVMESH_SRC)
    aux_source_directory(3rd/core/recastnavigation/Detour/Source Detour_SRC)
    aux_source_directory(3rd/core/recastnavigation/DetourCrowd/Source DetourCrowd_SRC)
    aux_source_directory(3rd/core/recastnavigation/DetourTileCache/Source DetourTileCache_SRC)
    aux_source_directory(3rd/core/recastnavigation/Recast/Source Recast_SRC)
    add_library(navmesh SHARED ${NAVMESH_SRC}
                    ${Detour_SRC} ${DetourCrowd_SRC}
                    ${DetourTileCache_SRC} ${Recast_SRC})
    target_include_directories(navmesh PRIVATE 
                    3rd/core/recastnavigation/Detour/Include/
                    3rd/core/recastnavigation/DetourCrowd/Include/
                    3rd/core/recastnavigation/DetourTileCache/Include/
                    3rd/core/recastnavigation/Recast/Include/)
    target_link_libraries(navmesh liblua)

    # 生成动态库 math3d.so
    aux_source_directory(3rd/luaclib/math3d MATH3D_SRC)
    add_library(math3d SHARED ${MATH3D_SRC})
    target_include_directories(math3d PRIVATE 3rd/core/glm/include/)
    target_compile_definitions(math3d PUBLIC -DGLM_ENABLE_EXPERIMENTAL -DGLM_FORCE_QUAT_DATA_XYZW)
    target_link_libraries(math3d liblua)

    # 生成动态库 rp3d.so
    aux_source_directory(3rd/luaclib/lua-rp3d RP3D_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/body/ RP3D_body_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/ RP3D_collision_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/broadphase/ RP3D_collision_broadphase_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/narrowphase/ RP3D_collision_narrowphase_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/narrowphase/GJK/ RP3D_collision_narrowphase_GJK_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/narrowphase/SAT/ RP3D_collision_narrowphase_SAT_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/shapes/ RP3D_collision_shapes_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/components/ RP3D_components_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/constraint/ RP3D_constraint_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/engine/ RP3D_engine_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/mathematics/ RP3D_mathematics_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/memory/ RP3D_memory_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/systems/ RP3D_systems_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/utils/ RP3D_utils_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/utils/quickhull/ RP3D_utils_quickhull_SRC)
    add_library(rp3d SHARED ${RP3D_SRC} ${RP3D_body_SRC} 
                ${RP3D_collision_SRC}  ${RP3D_collision_broadphase_SRC}
                ${RP3D_collision_narrowphase_SRC} ${RP3D_collision_narrowphase_GJK_SRC}
                ${RP3D_collision_narrowphase_SAT_SRC} ${RP3D_collision_shapes_SRC}
                ${RP3D_components_SRC} ${RP3D_constraint_SRC}
                ${RP3D_engine_SRC} ${RP3D_mathematics_SRC}
                ${RP3D_memory_SRC} ${RP3D_systems_SRC}
                ${RP3D_utils_SRC} ${RP3D_utils_quickhull_SRC} )
    target_include_directories(rp3d PRIVATE 3rd/core/reactphysics3d/include/
                3rd/core/reactphysics3d/include/reactphysics3d/body/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/broadphase/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/narrowphase/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/narrowphase/GJK/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/narrowphase/SAT/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/shapes/
                3rd/core/reactphysics3d/include/reactphysics3d/components/
                3rd/core/reactphysics3d/include/reactphysics3d/constraint/
                3rd/core/reactphysics3d/include/reactphysics3d/containers/
                3rd/core/reactphysics3d/include/reactphysics3d/engine/
                3rd/core/reactphysics3d/include/reactphysics3d/mathematics/
                3rd/core/reactphysics3d/include/reactphysics3d/memory/
                3rd/core/reactphysics3d/include/reactphysics3d/systems/
                3rd/core/reactphysics3d/include/reactphysics3d/utils/
                3rd/core/reactphysics3d/include/reactphysics3d/utils/quickhull/ )
    target_link_libraries(rp3d liblua)

    # 生成动态库 logrus.so
    aux_source_directory(3rd/luaclib/lua-logrus LOGRUS_SRC)
    add_library(logrus SHARED ${LOGRUS_SRC})
    target_include_directories(logrus PRIVATE 3rd/core/spdlog/include/)
    target_link_libraries(logrus ws2_32 liblua libposix pthreadVC3)

    set_target_properties(lpeg sproto client md5 bson skynetso
        pb lfs fmt yyjson  
        zset aoi navmesh math3d 
        rp3d logrus 
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/luaclib
        LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/luaclib
        PREFIX ""
        SUFFIX .so
    )

    # 生成c服务
    file(GLOB CSERVICE_FILE_LIST "skynet/service-src/*.c")
    message(STATUS "The value of CSERVICE_FILE_LIST is: ${CSERVICE_FILE_LIST}")
    foreach(FILE_PATH IN LISTS CSERVICE_FILE_LIST)
        message(STATUS "Processing file: ${FILE_PATH}")
        string(REGEX REPLACE ".*skynet/service-src/service_" "" LIB_NAME "${FILE_PATH}")
        string(REGEX REPLACE ".c$" "" LIB_NAME "${LIB_NAME}")
        message(STATUS "The value of LIB_NAME is: ${LIB_NAME}")
        add_library(${LIB_NAME} SHARED ${FILE_PATH})
        target_link_libraries(${LIB_NAME} ws2_32 libskynet)
        set_target_properties(${LIB_NAME} PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY  ${CMAKE_BINARY_DIR}/cservice
            LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/cservice
            PREFIX ""
            SUFFIX .so
            ENABLE_EXPORTS ON
            )
    endforeach()

endif ()

# MacOS
if (CMAKE_SYSTEM_NAME MATCHES "Darwin")
    message(STATUS "current platform: Mac OS X")
    add_compile_definitions(NOUSE_JEMALLOC LUA_USE_MACOSX LUA_USE_READLINE)

    set(CMAKE_C_FLAGS  " -O2 -Wall" )
    set(CMAKE_SHARED_LINKER_FLAGS " -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup")

    # 添加编译选项
    add_compile_options(-g)

    message(STATUS "The value of CMAKE_BINARY_DIR is: ${CMAKE_BINARY_DIR}")
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR})

    # 编译 skynet 可执行文件
    aux_source_directory(skynet/skynet-src SKYNET_SRC)
    aux_source_directory(skynet/3rd/lua LUA_LIB_SRC)
    list(REMOVE_ITEM LUA_LIB_SRC "skynet/3rd/lua/lua.c" "skynet/3rd/lua/luac.c" "skynet/3rd/lua/onelua.c")
    message(STATUS "The value of LUA_LIB_SRC is: ${LUA_LIB_SRC}")
    message(STATUS "The value of SKYNET_SRC is: ${SKYNET_SRC}")
    add_executable(skynet ${SKYNET_SRC} ${LUA_LIB_SRC})
    target_include_directories(skynet PRIVATE skynet/skynet-src)
    target_link_options(skynet PRIVATE)
    target_link_libraries(skynet m pthread dl)

    message(STATUS "The value of CMAKE_BINARY_DIR is: ${CMAKE_BINARY_DIR}")

    # 重新设置动态库输出路径
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/luaclib)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})

    # 生成动态库 skynet.so
    set(LUA_CLIB_SKYNET_SRC
        skynet/lualib-src/lua-skynet.c
        skynet/lualib-src/lua-seri.c
        skynet/lualib-src/lua-socket.c
        skynet/lualib-src/lua-mongo.c
        skynet/lualib-src/lua-netpack.c
        skynet/lualib-src/lua-memory.c
        skynet/lualib-src/lua-multicast.c
        skynet/lualib-src/lua-cluster.c
        skynet/lualib-src/lua-crypt.c
        skynet/lualib-src/lsha1.c
        skynet/lualib-src/lua-sharedata.c
        skynet/lualib-src/lua-stm.c
        skynet/lualib-src/lua-debugchannel.c
        skynet/lualib-src/lua-datasheet.c
        skynet/lualib-src/lua-sharetable.c )
    add_library(skynetso SHARED ${LUA_CLIB_SKYNET_SRC})
    target_include_directories(skynetso PRIVATE skynet/skynet-src skynet/lualib-src)
    set_target_properties(skynetso PROPERTIES OUTPUT_NAME skynet)
    set_target_properties(skynetso PROPERTIES PREFIX "" SUFFIX .so)

    # 生成动态库 bson.so
    add_library(bson SHARED skynet/lualib-src/lua-bson.c)
    target_include_directories(bson PRIVATE skynet/skynet-src)

    # 生成动态库 md5.so
    aux_source_directory(skynet/3rd/lua-md5 LUA_MD5_SRC)
    add_library(md5 SHARED ${LUA_MD5_SRC})

    # 生成动态库 client.so
    add_library(client SHARED skynet/lualib-src/lua-clientsocket.c
                            skynet/lualib-src/lua-crypt.c
                            skynet/lualib-src/lsha1.c)
    target_link_libraries(client pthread)

    # 生成动态库 sproto.so
    aux_source_directory(skynet/lualib-src/sproto SPROTO_SRC)
    add_library(sproto SHARED ${SPROTO_SRC})

    # 生成动态库 lpeg.so
    aux_source_directory(skynet/3rd/lpeg LPEG_SRC)
    add_library(lpeg SHARED ${LPEG_SRC})

    # 生成动态库 ltls.so
    add_library(ltls SHARED skynet/lualib-src/ltls.c)
    target_include_directories(ltls PRIVATE 3rd/core/openssl/include/)
    target_link_directories(ltls PRIVATE 3rd/core/openssl/lib/mac/)
    target_link_libraries(ltls ssl crypto)

    # 生成动态库 pb.so
    aux_source_directory(3rd/luaclib/lua-protobuf PB_SRC)
    add_library(pb SHARED ${PB_SRC})

    # 生成动态库 lfs.so
    aux_source_directory(3rd/luaclib/luafilesystem LFS_SRC)
    add_library(lfs SHARED ${LFS_SRC})

    # 生成动态库 fmt.so
    aux_source_directory(3rd/luaclib/lua-fmt FMT_SRC)
    add_library(fmt SHARED ${FMT_SRC})

    # 生成动态库 yyjson.so
    aux_source_directory(3rd/luaclib/lua-yyjson YYJSON_SRC)
    add_library(yyjson SHARED ${YYJSON_SRC})

    # 生成动态库 zset.so
    aux_source_directory(3rd/luaclib/lua-zset ZSET_SRC)
    add_library(zset SHARED ${ZSET_SRC})

    # 生成动态库 aoi.so
    aux_source_directory(3rd/luaclib/lua-aoi AOI_SRC)
    add_library(aoi SHARED ${AOI_SRC})

    # 生成动态库 navmesh.so
    aux_source_directory(3rd/luaclib/lua-navmesh NAVMESH_SRC)
    aux_source_directory(3rd/core/recastnavigation/Detour/Source Detour_SRC)
    aux_source_directory(3rd/core/recastnavigation/DetourCrowd/Source DetourCrowd_SRC)
    aux_source_directory(3rd/core/recastnavigation/DetourTileCache/Source DetourTileCache_SRC)
    aux_source_directory(3rd/core/recastnavigation/Recast/Source Recast_SRC)
    add_library(navmesh SHARED ${NAVMESH_SRC} 
                                ${Detour_SRC} ${DetourCrowd_SRC}
                                ${DetourTileCache_SRC} ${Recast_SRC} )
    target_include_directories(navmesh PRIVATE 
                                3rd/core/recastnavigation/Detour/Include/
                                3rd/core/recastnavigation/DetourCrowd/Include/
                                3rd/core/recastnavigation/DetourTileCache/Include/
                                3rd/core/recastnavigation/Recast/Include/)
    # 生成动态库 math3d.so
    aux_source_directory(3rd/luaclib/math3d MATH3D_SRC)
    add_library(math3d SHARED ${MATH3D_SRC})
    target_include_directories(math3d PRIVATE 3rd/core/glm/include/)
    target_compile_definitions(math3d PRIVATE -DGLM_ENABLE_EXPERIMENTAL -DGLM_FORCE_QUAT_DATA_XYZW)

    # 生成动态库 rp3d.so
    aux_source_directory(3rd/luaclib/lua-rp3d RP3D_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/body/ RP3D_body_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/ RP3D_collision_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/broadphase/ RP3D_collision_broadphase_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/narrowphase/ RP3D_collision_narrowphase_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/narrowphase/GJK/ RP3D_collision_narrowphase_GJK_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/narrowphase/SAT/ RP3D_collision_narrowphase_SAT_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/collision/shapes/ RP3D_collision_shapes_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/components/ RP3D_components_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/constraint/ RP3D_constraint_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/engine/ RP3D_engine_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/mathematics/ RP3D_mathematics_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/memory/ RP3D_memory_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/systems/ RP3D_systems_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/utils/ RP3D_utils_SRC)
    aux_source_directory(3rd/core/reactphysics3d/src/utils/quickhull/ RP3D_utils_quickhull_SRC)
    add_library(rp3d SHARED ${RP3D_SRC} ${RP3D_body_SRC} 
                ${RP3D_collision_SRC}  ${RP3D_collision_broadphase_SRC}
                ${RP3D_collision_narrowphase_SRC} ${RP3D_collision_narrowphase_GJK_SRC}
                ${RP3D_collision_narrowphase_SAT_SRC} ${RP3D_collision_shapes_SRC}
                ${RP3D_components_SRC} ${RP3D_constraint_SRC}
                ${RP3D_engine_SRC} ${RP3D_mathematics_SRC}
                ${RP3D_memory_SRC} ${RP3D_systems_SRC}
                ${RP3D_utils_SRC} ${RP3D_utils_quickhull_SRC} )
    target_include_directories(rp3d PRIVATE 3rd/core/reactphysics3d/include/
                3rd/core/reactphysics3d/include/reactphysics3d/body/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/broadphase/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/narrowphase/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/narrowphase/GJK/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/narrowphase/SAT/
                3rd/core/reactphysics3d/include/reactphysics3d/collision/shapes/
                3rd/core/reactphysics3d/include/reactphysics3d/components/
                3rd/core/reactphysics3d/include/reactphysics3d/constraint/
                3rd/core/reactphysics3d/include/reactphysics3d/containers/
                3rd/core/reactphysics3d/include/reactphysics3d/engine/
                3rd/core/reactphysics3d/include/reactphysics3d/mathematics/
                3rd/core/reactphysics3d/include/reactphysics3d/memory/
                3rd/core/reactphysics3d/include/reactphysics3d/systems/
                3rd/core/reactphysics3d/include/reactphysics3d/utils/
                3rd/core/reactphysics3d/include/reactphysics3d/utils/quickhull/ )

    # 生成动态库 logrus.so
    aux_source_directory(3rd/luaclib/lua-logrus LOGRUS_SRC)
    add_library(logrus SHARED ${LOGRUS_SRC})
    target_include_directories(logrus PRIVATE 3rd/core/spdlog/include/)
    target_link_libraries(logrus m pthread dl)

    set_target_properties(lpeg sproto client md5 bson ltls
        pb lfs fmt yyjson  
        zset aoi navmesh math3d 
        rp3d logrus
        PROPERTIES
        PREFIX ""
        SUFFIX .so
    )

    # 重新设置动态库输出路径
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/cservice)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})

    # 生成c服务
    file(GLOB CSERVICE_FILE_LIST "skynet/service-src/*.c")
    message(STATUS "The value of CSERVICE_FILE_LIST is: ${CSERVICE_FILE_LIST}")
    foreach(FILE_PATH IN LISTS CSERVICE_FILE_LIST)
        message(STATUS "Processing file: ${FILE_PATH}")
        string(REGEX REPLACE ".*skynet/service-src/service_" "" LIB_NAME "${FILE_PATH}")
        string(REGEX REPLACE ".c$" "" LIB_NAME "${LIB_NAME}")
        message(STATUS "The value of LIB_NAME is: ${LIB_NAME}")
        add_library(${LIB_NAME} SHARED ${FILE_PATH})
        target_include_directories(${LIB_NAME} PRIVATE skynet/skynet-src)
        set_target_properties(${LIB_NAME} PROPERTIES PREFIX "" SUFFIX .so)
    endforeach()

endif ()

# 拷贝其他文件
# CMAKE_SOURCE_DIR
message(STATUS "The value of CMAKE_SOURCE_DIR is: ${CMAKE_SOURCE_DIR}")
file(COPY ${CMAKE_SOURCE_DIR}/skynet/lualib/ DESTINATION lualib NO_SOURCE_PERMISSIONS)
file(COPY ${CMAKE_SOURCE_DIR}/skynet/test/ DESTINATION test NO_SOURCE_PERMISSIONS)
file(COPY ${CMAKE_SOURCE_DIR}/skynet/service/ DESTINATION service NO_SOURCE_PERMISSIONS)
file(COPY ${CMAKE_SOURCE_DIR}/skynet/examples/ DESTINATION examples NO_SOURCE_PERMISSIONS)
file(COPY ${CMAKE_SOURCE_DIR}/3rd/luaext/ DESTINATION luaext NO_SOURCE_PERMISSIONS)