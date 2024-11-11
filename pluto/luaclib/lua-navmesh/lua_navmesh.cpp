#include <lua.hpp>
#include "navmesh.hpp"

#define METANAME "__lnavmesh"

using navmesh_type = pluto::navmesh;

// https://en.cppreference.com/w/cpp/language/if
template <class>
inline constexpr bool dependent_false_v = false;

template <typename Type>
Type lua_check(lua_State *L, int index)
{
    using T = std::decay_t<Type>;
    if constexpr (std::is_same_v<T, std::string_view>)
    {
        size_t size;
        const char *sz = luaL_checklstring(L, index, &size);
        return std::string_view{sz, size};
    }
    else if constexpr (std::is_same_v<T, std::string>)
    {
        size_t size;
        const char *sz = luaL_checklstring(L, index, &size);
        return std::string{sz, size};
    }
    else if constexpr (std::is_same_v<T, bool>)
    {
        if (!lua_isboolean(L, index))
            luaL_typeerror(L, index, lua_typename(L, LUA_TBOOLEAN));
        return (bool)lua_toboolean(L, index);
    }
    else if constexpr (std::is_integral_v<T>)
    {
        auto v = luaL_checkinteger(L, index);
        luaL_argcheck(
            L,
            static_cast<lua_Integer>(static_cast<T>(v)) == v,
            index,
            "integer out-of-bounds");
        return static_cast<T>(v);
    }
    else if constexpr (std::is_floating_point_v<T>)
    {
        return static_cast<T>(luaL_checknumber(L, index));
    }
    else
    {
        static_assert(dependent_false_v<T>, "unsupport type");
    }
}

static int load_static(lua_State *L)
{
    auto meshfile = lua_check<std::string>(L, 1);
    std::string err;
    if (pluto::navmesh::load_static(meshfile, err))
    {
        lua_pushboolean(L, 1);
        return 1;
    }
    lua_pushboolean(L, 0);
    lua_pushlstring(L, err.data(), err.size());
    return 2;
}

static int load_dynamic(lua_State *L)
{
    navmesh_type *p = (navmesh_type *)lua_touserdata(L, 1);
    if (nullptr == p)
        return luaL_error(L, "Invalid navmesh pointer");

    auto meshfile = lua_check<std::string>(L, 2);
    std::string err;
    if (p->load_dynamic(meshfile, err))
    {
        lua_pushboolean(L, 1);
        return 1;
    }
    lua_pushboolean(L, 0);
    lua_pushlstring(L, err.data(), err.size());
    return 2;
}

static int find_straight_path(lua_State *L)
{
    navmesh_type *p = (navmesh_type *)lua_touserdata(L, 1);
    if (nullptr == p)
        return luaL_error(L, "Invalid navmesh pointer");
    auto sx = lua_check<float>(L, 2);
    auto sy = lua_check<float>(L, 3);
    auto sz = lua_check<float>(L, 4);
    auto ex = lua_check<float>(L, 5);
    auto ey = lua_check<float>(L, 6);
    auto ez = lua_check<float>(L, 7);
    std::vector<float> paths;
    if (p->find_straight_path(sx, sy, sz, ex, ey, ez, paths))
    {
        lua_createtable(L, (int)paths.size(), 0);
        for (size_t i = 0; i < paths.size(); ++i)
        {
            lua_pushnumber(L, paths[i]);
            lua_rawseti(L, -2, i + 1);
        }
        return 1;
    }
    lua_pushboolean(L, 0);
    lua_pushlstring(L, p->get_status().data(), p->get_status().size());
    return 2;
}

static int valid(lua_State *L)
{
    navmesh_type *p = (navmesh_type *)lua_touserdata(L, 1);
    if (nullptr == p)
        return luaL_error(L, "Invalid navmesh pointer");
    auto x = lua_check<float>(L, 2);
    auto y = lua_check<float>(L, 3);
    auto z = lua_check<float>(L, 4);
    bool res = p->valid(x, y, z);
    lua_pushboolean(L, res);
    return 1;
}

static int random_position(lua_State *L)
{
    navmesh_type *p = (navmesh_type *)lua_touserdata(L, 1);
    if (nullptr == p)
        return luaL_error(L, "Invalid navmesh pointer");
    float pos[3];
    if (p->random_position(pos))
    {
        lua_pushnumber(L, pos[0]);
        lua_pushnumber(L, pos[1]);
        lua_pushnumber(L, pos[2]);
        return 3;
    }
    lua_pushboolean(L, 0);
    return 1;
}

static int random_position_around_circle(lua_State *L)
{
    navmesh_type *p = (navmesh_type *)lua_touserdata(L, 1);
    if (nullptr == p)
        return luaL_error(L, "Invalid navmesh pointer");

    auto x = lua_check<float>(L, 2);
    auto y = lua_check<float>(L, 3);
    auto z = lua_check<float>(L, 4);
    auto r = lua_check<float>(L, 5);

    float pos[3];
    if (p->random_position_around_circle(x, y, z, r, pos))
    {
        lua_pushnumber(L, pos[0]);
        lua_pushnumber(L, pos[1]);
        lua_pushnumber(L, pos[2]);
        return 3;
    }
    lua_pushboolean(L, 0);
    return 1;
}

static int recast(lua_State *L)
{
    navmesh_type *p = (navmesh_type *)lua_touserdata(L, 1);
    if (nullptr == p)
        return luaL_error(L, "Invalid navmesh pointer");

    auto sx = lua_check<float>(L, 2);
    auto sy = lua_check<float>(L, 3);
    auto sz = lua_check<float>(L, 4);
    auto ex = lua_check<float>(L, 5);
    auto ey = lua_check<float>(L, 6);
    auto ez = lua_check<float>(L, 7);

    float hitPos[3];
    bool ok = p->recast(sx, sy, sz, ex, ey, ez, hitPos);
    lua_pushboolean(L, ok);
    lua_pushnumber(L, hitPos[0]);
    lua_pushnumber(L, hitPos[1]);
    lua_pushnumber(L, hitPos[2]);
    return 4;
}

static int add_capsule_obstacle(lua_State *L)
{
    navmesh_type *p = (navmesh_type *)lua_touserdata(L, 1);
    if (nullptr == p)
        return luaL_error(L, "Invalid navmesh pointer");

    auto x = lua_check<float>(L, 2);
    auto y = lua_check<float>(L, 3);
    auto z = lua_check<float>(L, 4);
    auto r = lua_check<float>(L, 5);
    auto h = lua_check<float>(L, 6);
    auto obstacleId = p->add_capsule_obstacle(x, y, z, r, h);
    if (obstacleId > 0)
    {
        lua_pushinteger(L, obstacleId);
        return 1;
    }
    return 0;
}

static int remove_obstacle(lua_State *L)
{
    navmesh_type *p = (navmesh_type *)lua_touserdata(L, 1);
    if (nullptr == p)
        return luaL_error(L, "Invalid navmesh pointer");

    auto obstacleId = lua_check<dtObstacleRef>(L, 2);
    auto res = p->remove_obstacle(obstacleId);
    lua_pushboolean(L, res);
    return 1;
}

static int clear_all_obstacle(lua_State *L)
{
    navmesh_type *p = (navmesh_type *)lua_touserdata(L, 1);
    if (nullptr == p)
        return luaL_error(L, "Invalid navmesh pointer");
    p->clear_all_obstacle();
    return 0;
}

static int update(lua_State *L)
{
    navmesh_type *p = (navmesh_type *)lua_touserdata(L, 1);
    if (nullptr == p)
        return luaL_error(L, "Invalid navmesh pointer");
    auto dt = lua_check<float>(L, 2);
    p->update(dt);
    return 0;
}

static int lrelease(lua_State *L)
{
    navmesh_type *p = (navmesh_type *)lua_touserdata(L, 1);
    if (nullptr == p)
        return luaL_error(L, "Invalid navmesh pointer");
    std::destroy_at(p);
    return 0;
}

static int lcreate(lua_State *L)
{
    std::string meshfile = luaL_optstring(L, 1, "");
    int mask = (int)luaL_optinteger(L, 2, 0);

    navmesh_type *p = (navmesh_type *)lua_newuserdatauv(L, sizeof(navmesh_type), 0);
    new (p) navmesh_type(meshfile, mask);

    if (luaL_newmetatable(L, METANAME)) // mt
    {
        luaL_Reg l[] = {{"load_dynamic", load_dynamic},
                        {"find_straight_path", find_straight_path},
                        {"valid", valid},
                        {"random_position", random_position},
                        {"random_position_around_circle", random_position_around_circle},
                        {"recast", recast},
                        {"add_capsule_obstacle", add_capsule_obstacle},
                        {"remove_obstacle", remove_obstacle},
                        {"clear_all_obstacle", clear_all_obstacle},
                        {"update", update},
                        {NULL, NULL}};
        luaL_newlib(L, l);              //{}
        lua_setfield(L, -2, "__index"); // mt[__index] = {}
        lua_pushcfunction(L, lrelease);
        lua_setfield(L, -2, "__gc"); // mt[__gc] = lrelease
    }
    lua_setmetatable(L, -2); // set userdata metatable
    lua_pushlightuserdata(L, p);
    return 2;
}

extern "C"
{
    int luaopen_navmesh(lua_State *L)
    {
        luaL_Reg l[] = {{"new", lcreate}, {"load_static", load_static}, {NULL, NULL}};
        luaL_newlib(L, l);
        return 1;
    }
}
