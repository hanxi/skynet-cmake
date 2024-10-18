#include <limits.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include "fibheap.h"
#include "jps.h"
#include "map.h"
#include "smooth.h"

#define MT_NAME ("_nav_metatable")

static inline int getfield(lua_State* L, const char* f) {
    if (lua_getfield(L, -1, f) != LUA_TNUMBER) {
        return luaL_error(L, "invalid type %s", f);
    }
    int v = lua_tointeger(L, -1);
    lua_pop(L, 1);
    return v;
}

static inline int setobstacle(lua_State* L, Map* m, int x, int y) {
    if (!check_in_map(x, y, m->width, m->height)) {
        luaL_error(L, "Position (%d,%d) is out of map", x, y);
    }
    BITSET(m->m, m->width * y + x);
    return 0;
}

static void push_path_to_istack(lua_State* L, Map* m) {
    lua_newtable(L);
    int i, x, y;
    int num = 1;
    for (i = m->ipath_len - 1; i >= 0; i--) {
        pos2xy(m, m->ipath[i], &x, &y);
        // printf("pos:%d x:%d y:%d\n", m->ipath[i], x, y);
        lua_newtable(L);
        lua_pushinteger(L, x);
        lua_rawseti(L, -2, 1);
        lua_pushinteger(L, y);
        lua_rawseti(L, -2, 2);
        lua_rawseti(L, -2, num++);
    }
}

static void push_fpos(lua_State* L, float fx, float fy, int num) {
    lua_newtable(L);
    lua_pushnumber(L, fx);
    lua_rawseti(L, -2, 1);
    lua_pushnumber(L, fy);
    lua_rawseti(L, -2, 2);
    lua_rawseti(L, -2, num);
}

static void find_walkable_point_in_cell(Map* m, int center_pos, float fx1, float fy1,
    float fx2, float fy2, float* x, float* y) {
    int x0, y0, ix, iy;
    float fx0, fy0;
    pos2xy(m, center_pos, &ix, &iy);

    for(x0 = ix; x0 <= ix + 1; x0 ++) {
        for(y0 = iy; y0 <= iy + 1; y0 ++) {
            fx0 = x0 == ix ? x0 - 0.1 : x0 + 0.1;
            fy0 = y0 == iy ? y0 - 0.1 : y0 + 0.1;
            if(find_line_obstacle(m, fx0, fy0, fx1, fy1) < 0 && find_line_obstacle(m, fx0, fy0, fx2, fy2) < 0) {
                *x = x0;
                *y = y0;
                return;
            }
        }
    }
}

static void push_path_to_fstack(lua_State* L,
                                Map* m,
                                float fx1,
                                float fy1,
                                float fx2,
                                float fy2) {
    lua_newtable(L);
    int i, ix, iy;
    float fx, fy;
    int num = 1;
    if (m->ipath_len < 2) {
        return;
    }

    push_fpos(L, fx1, fy1, num++);
    pos2xy(m, m->ipath[m->ipath_len - 2], &ix, &iy);

    int obs_pos = find_line_obstacle(m, fx1, fy1, ix + 0.5, iy + 0.5);
    if (obs_pos >= 0) {
        // 插入起点到第二个路点间的拐点
        fx = -1;
        fy = -1;
        find_walkable_point_in_cell(m, obs_pos, ix + 0.5, iy + 0.5, fx1, fy1, &fx, &fy);
        if(fx >= 0 && fy >= 0) {
            push_fpos(L, fx, fy, num++);
        }
    }

    for (i = m->ipath_len - 2; i >= 1; i--) {
        pos2xy(m, m->ipath[i], &ix, &iy);
        push_fpos(L, ix + 0.5, iy + 0.5, num++);
    }

    if (m->ipath_len > 2) {
        // 插入倒数第二个路点到终点间的拐点
        obs_pos = find_line_obstacle(m, ix + 0.5, iy + 0.5, fx2, fy2);
        if (obs_pos >= 0) {
            fx = -1;
            fy = -1;
            find_walkable_point_in_cell(m, obs_pos, ix + 0.5, iy + 0.5, fx2, fy2, &fx, &fy);
            if(fx >= 0 && fy >= 0) {
                push_fpos(L, fx, fy, num++);
            }
        }
    }
    push_fpos(L, fx2, fy2, num++);
}

static int insert_mid_jump_point(Map* m, int cur, int father) {
    int w = m->width;
    int dx = cur % w - father % w;
    int dy = cur / w - father / w;
    if (dx == 0 || dy == 0) {
        return 0;
    }
    if (dx < 0) {
        dx = -dx;
    }
    if (dy < 0) {
        dy = -dy;
    }
    if (dx == dy) {
        return 0;
    }
    int span = dx;
    if (dy < dx) {
        span = dy;
    }
    int mx = 0, my = 0;
    if (cur % w < father % w && cur / w < father / w) {
        mx = father % w - span;
        my = father / w - span;
    } else if (cur % w < father % w && cur / w > father / w) {
        mx = father % w - span;
        my = father / w + span;
    } else if (cur % w > father % w && cur / w < father / w) {
        mx = father % w + span;
        my = father / w - span;
    } else if (cur % w > father % w && cur / w > father / w) {
        mx = father % w + span;
        my = father / w + span;
    }
    push_pos_to_ipath(m, xy2pos(m, mx, my));
    return 1;
}

static void flood_mark(struct map *m, int pos, int connected_num, int limit) {
    char *visited = m->visited;
    if (visited[pos]) {
        return;
    }
    int *queue = m->queue;
    memset(queue, 0, limit * sizeof(int));
    int pop_i = 0, push_i = 0;
    visited[pos] = 1;
    m->connected[pos] = connected_num;
    queue[push_i++] = pos;

#define CHECK_POS(n) do { \
    if (!BITTEST(m->m, n)) { \
        if (!visited[n]) { \
            visited[n] = 1; \
            m->connected[n] = connected_num; \
            queue[push_i++] = n; \
        } \
    } \
} while(0);
    int cur, left;
    while (pop_i < push_i) {
        cur = queue[pop_i++];
        left = cur % m->width;
        if (left != 0) {
            CHECK_POS(cur - 1);
        }
        if (left != m->width - 1) {
            CHECK_POS(cur + 1);
        }
        if (cur >= m->width) {
            CHECK_POS(cur - m->width);
        }
        if (cur < limit - m->width) {
            CHECK_POS(cur + m->width);
        }
    }
#undef CHECK_POS
}

static int lnav_add_block(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    if (!check_in_map(x, y, m->width, m->height)) {
        luaL_error(L, "Position (%d,%d) is out of map", x, y);
    }
    BITSET(m->m, m->width * y + x);
    return 0;
}

static int lnav_is_block(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    int block = BITTEST(m->m, m->width * y + x);
    lua_pushboolean(L, block);
    return 1;
}

static int lnav_get_connected_id(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    lua_pushnumber(L, m->connected[m->width * y + x]);
    return 1;
}

static int lnav_blockset(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    luaL_checktype(L, 2, LUA_TTABLE);
    lua_settop(L, 2);
    int i = 1;
    while (lua_geti(L, -1, i) == LUA_TTABLE) {
        lua_geti(L, -1, 1);
        int x = lua_tointeger(L, -1);
        lua_geti(L, -2, 2);
        int y = lua_tointeger(L, -1);
        setobstacle(L, m, x, y);
        lua_pop(L, 3);
        ++i;
    }
    return 0;
}

static int lnav_clear_block(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    if (!check_in_map(x, y, m->width, m->height)) {
        luaL_error(L, "Position (%d,%d) is out of map", x, y);
    }
    BITCLEAR(m->m, m->width * y + x);
    return 0;
}

static int lnav_clear_allblock(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    int i;
    for (i = 0; i < m->width * m->height; i++) {
        BITCLEAR(m->m, i);
    }
    return 0;
}

static int lnav_mark_connected(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);

    m->mark_connected = 1;
    int len = m->width * m->height;
    memset(m->connected, 0, len * sizeof(int));
    memset(m->visited, 0, len * sizeof(char));
    int i, connected_num = 0;
    for (i = 0; i < len; i++) {
        if (!m->visited[i] && !BITTEST(m->m, i)) {
            flood_mark(m, i, ++connected_num, len);
        }
    }

    return 0;
}

static int lnav_dump_connected(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    printf("dump map connected state!!!!!!\n");
    if (!m->mark_connected) {
        printf("have not mark connected.\n");
        return 0;
    }
    int i;
    for (i = 0; i < m->width * m->height; i++) {
        int mark = m->connected[i];
        if (mark > 0) {
            printf("%d ", mark);
        } else {
            printf("* ");
        }
        if ((i + 1) % m->width == 0) {
            printf("\n");
        }
    }
    return 0;
}

static int lnav_dump(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    printf("dump map state!!!!!!\n");
    int i, pos;
    char *s = (char*)malloc((m->width * 2 + 2) * sizeof(char));
    for (pos = 0, i = 0; i < m->width * m->height; i++) {
        if (i > 0 && i % m->width == 0) {
            s[pos - 1] = '\0';
            printf("%s\n", s);
            pos = 0;
        }
        int mark = 0;
        if (BITTEST(m->m, i)) {
            s[pos++] = '*';
            mark = 1;
        }
        if (i == m->start) {
            s[pos++] = 'S';
            mark = 1;
        }
        if (i == m->end) {
            s[pos++] = 'E';
            mark = 1;
        }
        if (mark) {
            s[pos++] = ' ';
        } else {
            s[pos++] = '.';
            s[pos++] = ' ';
        }
    }
    s[pos - 1] = '\0';
    printf("%s\n", s);
    free(s);
    return 0;
}

static int gc(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    free(m->comefrom);
    free(m->open_set_map);
    if (m->mark_connected) {
        free(m->connected);
    }
    free(m->queue);
    free(m->visited);
    return 0;
}

static void form_ipath(Map* m, int last) {
    int pos = last;
    m->ipath_len = 0;

    while (m->comefrom[pos] != -1) {
        push_pos_to_ipath(m, pos);
        insert_mid_jump_point(m, pos, m->comefrom[pos]);
        pos = m->comefrom[pos];
    }
    push_pos_to_ipath(m, m->start);
}

static int lnav_check_line_walkable(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    float x1 = luaL_checknumber(L, 2);
    float y1 = luaL_checknumber(L, 3);
    float x2 = luaL_checknumber(L, 4);
    float y2 = luaL_checknumber(L, 5);
    lua_pushboolean(L, find_line_obstacle(m, x1, y1, x2, y2) < 0);
    return 1;
}

static int lnav_find_path(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    float fx1 = luaL_checknumber(L, 2);
    float fy1 = luaL_checknumber(L, 3);
    int x = fx1;
    int y = fy1;
    if (check_in_map(x, y, m->width, m->height)) {
        m->start = m->width * y + x;
    } else {
        luaL_error(L, "Position (%d,%d) is out of map", x, y);
    }
    float fx2 = luaL_checknumber(L, 4);
    float fy2 = luaL_checknumber(L, 5);
    x = fx2;
    y = fy2;
    if (check_in_map(x, y, m->width, m->height)) {
        m->end = m->width * y + x;
    } else {
        luaL_error(L, "Position (%d,%d) is out of map", x, y);
    }
    if(floor(fx1) == floor(fx2) && floor(fy1) == floor(fy2)) {
        lua_newtable(L);
        push_fpos(L, fx1, fy1, 1);
        push_fpos(L, fx2, fy2, 2);
        return 1;
    }
    if (BITTEST(m->m, m->start)) {
        // luaL_error(L, "start pos(%d,%d) is in block", m->start % m->width,
        //            m->start / m->width);
        return 0;
    }
    if (BITTEST(m->m, m->end)) {
        // luaL_error(L, "end pos(%d,%d) is in block", m->end % m->width,
        //            m->end / m->width);
        return 0;
    }
    if (m->connected[m->start] != m->connected[m->end]) {
        return 0;
    }
    int start_pos = jps_find_path(m);
    if (start_pos >= 0) {
        form_ipath(m, start_pos);
        smooth_path(m);
        push_path_to_fstack(L, m, fx1, fy1, fx2, fy2);
        return 1;
    }
    return 0;
}

static int lnav_find_path_by_grid(lua_State* L) {
    Map* m = luaL_checkudata(L, 1, MT_NAME);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    if (check_in_map(x, y, m->width, m->height)) {
        m->start = m->width * y + x;
    } else {
        luaL_error(L, "Position (%d,%d) is out of map", x, y);
    }
    x = luaL_checkinteger(L, 4);
    y = luaL_checkinteger(L, 5);
    if (check_in_map(x, y, m->width, m->height)) {
        m->end = m->width * y + x;
    } else {
        luaL_error(L, "Position (%d,%d) is out of map", x, y);
    }
    if (BITTEST(m->m, m->start)) {
        luaL_error(L, "start pos(%d,%d) is in block", m->start % m->width,
                   m->start / m->width);
        return 0;
    }
    if (BITTEST(m->m, m->end)) {
        luaL_error(L, "end pos(%d,%d) is in block", m->end % m->width,
                   m->end / m->width);
        return 0;
    }
    int without_smooth = lua_toboolean(L, 6);
    int start_pos = jps_find_path(m);
    if (start_pos >= 0) {
        form_ipath(m, start_pos);
        if (!without_smooth) {
            smooth_path(m);
        }
        push_path_to_istack(L, m);
        return 1;
    }
    return 0;
}

static int lmetatable(lua_State* L) {
    if (luaL_newmetatable(L, MT_NAME)) {
        luaL_Reg l[] = {{"add_block", lnav_add_block},
                        {"add_blockset", lnav_blockset},
                        {"clear_block", lnav_clear_block},
                        {"clear_allblock", lnav_clear_allblock},
                        {"is_block", lnav_is_block},
                        {"find_path_by_grid", lnav_find_path_by_grid},
                        {"find_path", lnav_find_path},
                        {"find_line_obstacle", lnav_check_line_walkable},
                        {"get_connected_id", lnav_get_connected_id},
                        {"mark_connected", lnav_mark_connected},
                        {"dump_connected", lnav_dump_connected},
                        {"dump", lnav_dump},
                        {NULL, NULL}};
        luaL_newlib(L, l);
        lua_setfield(L, -2, "__index");

        lua_pushcfunction(L, gc);
        lua_setfield(L, -2, "__gc");
    }
    return 1;
}

static int lnewmap(lua_State* L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_settop(L, 1);
    int width = getfield(L, "w");
    int height = getfield(L, "h");
    lua_assert(width > 0 && height > 0);
    int len = width * height;

    int map_men_len = (BITSLOT(len) + 1) * 2;

    Map* m = lua_newuserdata(L, sizeof(Map) + map_men_len * sizeof(m->m[0]));
    init_map(m, width, height, map_men_len);
    if (lua_getfield(L, 1, "obstacle") == LUA_TTABLE) {
        int i = 1;
        while (lua_geti(L, -1, i) == LUA_TTABLE) {
            lua_geti(L, -1, 1);
            int x = lua_tointeger(L, -1);
            lua_geti(L, -2, 2);
            int y = lua_tointeger(L, -1);
            setobstacle(L, m, x, y);
            lua_pop(L, 3);
            ++i;
        }
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
    lmetatable(L);
    lua_setmetatable(L, -2);
    return 1;
}

int luaopen_jps(lua_State* L) {
    luaL_checkversion(L);
    luaL_Reg l[] = {
        {"new", lnewmap},
        {NULL, NULL},
    };
    luaL_newlib(L, l);
    return 1;
}