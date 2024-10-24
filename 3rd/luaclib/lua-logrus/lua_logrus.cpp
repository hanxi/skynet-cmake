#include <lua.hpp>
#include "logrus.h"

using namespace logrus;

#define METANAME "__logrus"

static int logrus_release(lua_State *L)
{
    Logrus *p = (Logrus *)lua_touserdata(L, 1);
    if (nullptr == p)
    {
        return luaL_argerror(L, 1, "invalid lua-logrus pointer");
    }
    std::destroy_at(p);
    return 0;
}

static int logrus_debug(lua_State *L)
{
    Logrus *p = (Logrus *)lua_touserdata(L, 1);
    if (nullptr == p)
    {
        return luaL_argerror(L, 1, "invalid lua-logrus pointer");
    }

    size_t sz;
    const char *buffer = lua_tolstring(L, 2, &sz);
    p->debug(std::string(buffer, sz));
    return 0;
}

static int logrus_info(lua_State *L)
{
    Logrus *p = (Logrus *)lua_touserdata(L, 1);
    if (nullptr == p)
    {
        return luaL_argerror(L, 1, "invalid lua-logrus pointer");
    }

    size_t sz;
    const char *buffer = lua_tolstring(L, 2, &sz);
    p->info(std::string(buffer, sz));
    return 0;
}

static int logrus_warn(lua_State *L)
{
    Logrus *p = (Logrus *)lua_touserdata(L, 1);
    if (nullptr == p)
    {
        return luaL_argerror(L, 1, "invalid lua-logrus pointer");
    }

    size_t sz;
    const char *buffer = lua_tolstring(L, 2, &sz);
    p->warn(std::string(buffer, sz));
    return 0;
}

static int logrus_error(lua_State *L)
{
    Logrus *p = (Logrus *)lua_touserdata(L, 1);
    if (nullptr == p)
    {
        return luaL_argerror(L, 1, "invalid lua-logrus pointer");
    }

    size_t sz;
    const char *buffer = lua_tolstring(L, 2, &sz);
    p->error(std::string(buffer, sz));
    return 0;
}

static int logrus_fatal(lua_State *L)
{
    Logrus *p = (Logrus *)lua_touserdata(L, 1);
    if (nullptr == p)
    {
        return luaL_argerror(L, 1, "invalid lua-logrus pointer");
    }

    size_t sz;
    const char *buffer = lua_tolstring(L, 2, &sz);
    p->fatal(std::string(buffer, sz));
    return 0;
}

static int logrus_hex(lua_State *L)
{
    Logrus *p = (Logrus *)lua_touserdata(L, 1);
    if (nullptr == p)
    {
        return luaL_argerror(L, 1, "invalid lua-logrus pointer");
    }

    size_t sz;
    const char *buffer = lua_tolstring(L, 2, &sz);
    auto hex = p->hex(std::string(buffer, sz));
    p->info(hex);
    return 0;
}

static int logrus_create(lua_State *L)
{
    std::string logname = luaL_optstring(L, 1, "logrus");
    std::string filename = luaL_optstring(L, 2, "skynet");

    Logrus *p = (Logrus *)lua_newuserdatauv(L, sizeof(Logrus), 0);
    new (p) Logrus(logname, kIsDefaultLogger);
    p->configFilename(filename).init();

    if (luaL_newmetatable(L, METANAME)) // mt
    {
        luaL_Reg l[] = {
            {"debug", logrus_debug},
            {"info", logrus_info},
            {"warn", logrus_warn},
            {"error", logrus_error},
            {"fatal", logrus_fatal},
            {"hex", logrus_hex},
            {NULL, NULL}};
        luaL_newlib(L, l);              //{}
        lua_setfield(L, -2, "__index"); // mt[__index] = {}
        lua_pushcfunction(L, logrus_release);
        lua_setfield(L, -2, "__gc"); // mt[__gc] = lrelease
    }
    lua_setmetatable(L, -2); // set userdata metatable
    return 1;
}

extern "C"
{
    int luaopen_logrus(lua_State *L)
    {
        luaL_Reg l[] = {{"new", logrus_create}, {NULL, NULL}};
        luaL_newlib(L, l);
        return 1;
    }
}