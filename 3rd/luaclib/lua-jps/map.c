
#include "map.h"

void push_pos_to_ipath(Map* m, int ipos) {
    m->ipath_len++;
    if (m->ipath_len > m->ipath_cap) {
        int* old_path = m->ipath;
        m->ipath_cap *= 2;
        m->ipath = (int*)malloc(sizeof(int) * m->ipath_cap);
        memcpy(m->ipath, old_path, sizeof(int) * (m->ipath_len - 1));
        free(old_path);
    }
    m->ipath[m->ipath_len - 1] = ipos;
    // printf("add pos to ipath %d\n", m->ipath[m->ipath_len - 1]);
}

void init_map(Map* m, int width, int height, int map_men_len) {
    int len = width * height;
    m->width = width;
    m->height = height;
    m->start = -1;
    m->end = -1;
    m->mark_connected = 0;
    m->comefrom = (int*)malloc(len * sizeof(int));
    m->ipath_cap = 2;
    m->ipath_len = 0;
    m->ipath = (int*)malloc(m->ipath_cap * sizeof(int));
    m->visited = (char*)malloc(len * sizeof(char));
    m->queue = (int *)malloc(len * sizeof(int));
    m->connected = (int *)malloc(len * sizeof(int));
    m->open_set_map =
        (struct heap_node**)malloc(len * sizeof(struct heap_node*));
    memset(m->m, 0, map_men_len * sizeof(m->m[0]));
}

int dist(int one, int two, int w) {
    int ex = one % w, ey = one / w;
    int px = two % w, py = two / w;
    int dx = ex - px, dy = ey - py;
    if (dx < 0) {
        dx = -dx;
    }
    if (dy < 0) {
        dy = -dy;
    }
    if (dx < dy) {
        return dx * 7 + (dy - dx) * 5;
    } else {
        return dy * 7 + (dx - dy) * 5;
    }
}

inline int map_walkable(Map* m, int pos) {
    return check_in_map_pos(pos, m->width * m->height) && !BITTEST(m->m, pos);
}