/*
** LuaSystemLog
** Copyright 1994-2021 Nicolas Casalini (DarkGod)
**
*/

#include <syslog.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static int lsyslog_open(lua_State *L)
{
	const char *ident = luaL_checkstring(L, 1);
	int facility = luaL_checkinteger(L, 2);

	lua_pushvalue(L,1);
	lua_setfield(L, LUA_REGISTRYINDEX, "luasyslog:ident");
	openlog(ident, LOG_PID, facility);
	return 0;
}

static int lsyslog_log(lua_State *L)
{
	int level = luaL_checkinteger(L, 1);
	const char *line = luaL_checkstring(L, 2);

	syslog(level, "%s", line);
	return 0;
}

static int lsyslog_close(lua_State *L)
{
	closelog();
	lua_pushnil(L);
	lua_setfield(L, LUA_REGISTRYINDEX, "luasyslog:ident");
	return 0;
}

/*
** Assumes the table is on top of the stack.
*/
static void set_info (lua_State *L)
{
	lua_pushliteral (L, "_COPYRIGHT");
	lua_pushliteral (L, "Copyright (C) 1994-2021 Nicolas Casalini (DarkGod)");
	lua_settable (L, -3);
	lua_pushliteral (L, "_DESCRIPTION");
	lua_pushliteral (L, "LuaSyslog allows to use log to an unix Syslog daemon, direct or via LuaLogging");
	lua_settable (L, -3);
	lua_pushliteral (L, "_VERSION");
	lua_pushliteral (L, "LuaSyslog 2.0.1");
	lua_settable (L, -3);

	lua_pushliteral(L, "FACILITY_AUTH");
	lua_pushnumber(L,  LOG_AUTH);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_AUTHPRIV");
	lua_pushnumber(L,  LOG_AUTHPRIV);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_CRON");
	lua_pushnumber(L,  LOG_CRON);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_DAEMON");
	lua_pushnumber(L,  LOG_DAEMON);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_FTP");
	lua_pushnumber(L,  LOG_FTP);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_KERN");
	lua_pushnumber(L,  LOG_KERN);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_LPR");
	lua_pushnumber(L,  LOG_LPR);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_MAIL");
	lua_pushnumber(L,  LOG_MAIL);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_NEWS");
	lua_pushnumber(L,  LOG_NEWS);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_SYSLOG");
	lua_pushnumber(L,  LOG_SYSLOG);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_USER");
	lua_pushnumber(L,  LOG_USER);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_UUCP");
	lua_pushnumber(L,  LOG_UUCP);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_LOCAL0");
	lua_pushnumber(L,  LOG_LOCAL0);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_LOCAL1");
	lua_pushnumber(L,  LOG_LOCAL1);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_LOCAL2");
	lua_pushnumber(L,  LOG_LOCAL2);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_LOCAL3");
	lua_pushnumber(L,  LOG_LOCAL3);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_LOCAL4");
	lua_pushnumber(L,  LOG_LOCAL4);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_LOCAL5");
	lua_pushnumber(L,  LOG_LOCAL5);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_LOCAL6");
	lua_pushnumber(L,  LOG_LOCAL6);
	lua_settable(L, -3);
	lua_pushliteral(L, "FACILITY_LOCAL7");
	lua_pushnumber(L,  LOG_LOCAL7);
	lua_settable(L, -3);

	lua_pushliteral(L, "LOG_EMERG");
	lua_pushnumber(L,  LOG_EMERG);
	lua_settable(L, -3);
	lua_pushliteral(L, "LOG_ALERT");
	lua_pushnumber(L,  LOG_ALERT);
	lua_settable(L, -3);
	lua_pushliteral(L, "LOG_CRIT");
	lua_pushnumber(L,  LOG_CRIT);
	lua_settable(L, -3);
	lua_pushliteral(L, "LOG_ERR");
	lua_pushnumber(L,  LOG_ERR);
	lua_settable(L, -3);
	lua_pushliteral(L, "LOG_WARNING");
	lua_pushnumber(L,  LOG_WARNING);
	lua_settable(L, -3);
	lua_pushliteral(L, "LOG_NOTICE");
	lua_pushnumber(L,  LOG_NOTICE);
	lua_settable(L, -3);
	lua_pushliteral(L, "LOG_INFO");
	lua_pushnumber(L,  LOG_INFO);
	lua_settable(L, -3);
	lua_pushliteral(L, "LOG_DEBUG");
	lua_pushnumber(L,  LOG_DEBUG);
	lua_settable(L, -3);
}

static const struct luaL_Reg lsysloglib[] =
{
	{"open", lsyslog_open},
	{"close", lsyslog_close},
	{"log", lsyslog_log},
	{NULL, NULL},
};

int luaopen_lsyslog(lua_State *L)
{
	lua_newtable(L);

#if LUA_VERSION_NUM < 502
    // Lua 5.1 compatibility, exposing a global
	luaL_register(L, "lsyslog", lsysloglib);
#else
	// Lua 5.2+ no global, just return a table
	luaL_setfuncs (L, lsysloglib, 0);
#endif

	set_info(L);
	return 1;
}