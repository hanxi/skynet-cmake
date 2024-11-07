#include <stdlib.h>
#include <string.h>
#include <syslog.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>


static int
lsyslog_open(lua_State *L)
{
    static char *persistent_ident = NULL;
    const char *ident = luaL_checkstring(L, 1);
    int facility = luaL_checkinteger(L, 2);

    if (persistent_ident != NULL) {
        free(persistent_ident);
    }

    persistent_ident = strdup(ident);
    openlog(persistent_ident, LOG_PID, facility);
    return 0;
}

static int
lsyslog_log(lua_State *L)
{
    int level = luaL_checkinteger(L, 1);
    const char *line = luaL_checkstring(L, 2);

    syslog(level, "%s", line);
    return 0;
}

static int
lsyslog_close(lua_State *L)
{
    closelog();
    return 0;
}


#define set_field(f,v)          lua_pushliteral(L, v); \
                                lua_setfield(L, -2, f)
#define add_constant(c)         lua_pushinteger(L, LOG_##c); \
                                lua_setfield(L, -2, #c)

int
luaopen_lsyslog(lua_State *L)
{
    const luaL_Reg API[] = {
        { "open",  lsyslog_open },
        { "close", lsyslog_close },
        { "log",   lsyslog_log },
        { NULL,    NULL }
    };

    luaL_newlib(L, API);

    lua_newtable(L);
    add_constant(AUTH);
    add_constant(AUTHPRIV);
    add_constant(CRON);
    add_constant(DAEMON);
    add_constant(FTP);
    add_constant(KERN);
    add_constant(LOCAL0);
    add_constant(LOCAL1);
    add_constant(LOCAL2);
    add_constant(LOCAL3);
    add_constant(LOCAL4);
    add_constant(LOCAL5);
    add_constant(LOCAL6);
    add_constant(LOCAL7);
    add_constant(LPR);
    add_constant(MAIL);
    add_constant(NEWS);
    add_constant(SYSLOG);
    add_constant(USER);
    add_constant(UUCP);
    lua_setfield(L, -2, "FACILITY");

    lua_newtable(L);
    add_constant(EMERG);
    add_constant(ALERT);
    add_constant(CRIT);
    add_constant(ERR);
    add_constant(WARNING);
    add_constant(NOTICE);
    add_constant(INFO);
    add_constant(DEBUG);
    lua_setfield(L, -2, "LEVEL");

    return 1;
}