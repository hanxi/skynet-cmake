#include "jps.h"
#include "fibheap.h"

static struct node_data *construct(Map *m, int pos, int g_value,
            unsigned char dir) {
    struct node_data *node = (struct node_data *)malloc(sizeof(struct node_data));
    node->pos = pos;
    node->g_value = g_value;
    node->f_value = g_value + dist(m->end, pos, m->width);
    node->dir = dir;
    return node;
}

static int get_next_pos(int pos, unsigned char dir, int w, int h) {
    int x = pos % w;
    int y = pos / w;
    switch (dir) {
        case 0:
            y = y - 1;
            break;
        case 1:
            x = x + 1;
            y = y - 1;
            break;
        case 2:
            x = x + 1;
            break;
        case 3:
            x = x + 1;
            y = y + 1;
            break;
        case 4:
            y = y + 1;
            break;
        case 5:
            x = x - 1;
            y = y + 1;
            break;
        case 6:
            x = x - 1;
            break;
        case 7:
            x = x - 1;
            y = y - 1;
            break;
        default: return -1;
    }
    if (!check_in_map(x, y, w, h)) {
        return -1;
    }
    return x + y * w;
}

static inline int walkable(Map *m, int pos, int cur_dir, int next_dir) {
    return map_walkable(m, get_next_pos(pos, (cur_dir + (next_dir)) % 8, m->width, m->height));
}

static unsigned char natural_dir(int pos, unsigned char cur_dir, Map *m) {
    unsigned char dir_set = EMPTY_DIRECTIONSET;
    if (cur_dir == NO_DIRECTION) {
        return FULL_DIRECTIONSET;
    }

    dir_add(&dir_set, cur_dir);
    if (dir_is_diagonal(cur_dir)) {
        dir_add(&dir_set, (cur_dir + 1) % 8);
        dir_add(&dir_set, (cur_dir + 7) % 8);
    }

    return dir_set;
}

static unsigned char force_dir(int pos, unsigned char cur_dir, Map *m) {
    if (cur_dir == NO_DIRECTION) {
        return EMPTY_DIRECTIONSET;
    }
    unsigned char dir_set = EMPTY_DIRECTIONSET;
#define WALKABLE(n) walkable(m, pos, cur_dir, n)
    if (dir_is_diagonal(cur_dir)) {
        if (WALKABLE(6) && !WALKABLE(5)) {
            dir_add(&dir_set, (cur_dir + 6) % 8);
        }
        if (WALKABLE(2) && !WALKABLE(3)) {
            dir_add(&dir_set, (cur_dir + 2) % 8);
        }
    } else {
        if (WALKABLE(1) && !WALKABLE(2)) {
            dir_add(&dir_set, (cur_dir + 1) % 8);
        }
        if (WALKABLE(7) && !WALKABLE(6)) {
            dir_add(&dir_set, (cur_dir + 7) % 8);
        }
    }
#undef WALKABLE
    return dir_set;
}

static unsigned char next_dir(unsigned char *dirs) {
    unsigned char dir;
    for (dir = 0 ; dir < 8 ; dir++) {
        char dirBit = 1 << dir;
        if (*dirs & dirBit) {
            *dirs ^= dirBit;
            return dir;
        }
    }
    return NO_DIRECTION;
}

static void put_in_open_set(struct heap *open_set, Map *m, int pos,
            int len, struct node_data *node, unsigned char dir) {
    if (!BITTEST(m->m, (BITSLOT(len) + 1) * CHAR_BIT + pos)) {
        int ng_value = node->g_value + dist(pos, node->pos, m->width);
        struct heap_node *p = m->open_set_map[pos];
        if (!p) {
            m->comefrom[pos] = node->pos;
            struct node_data *test = construct(m, pos, ng_value, dir);
            m->open_set_map[pos] = fibheap_insert(open_set, test);
        } else if (p->data->g_value > ng_value) {
            m->comefrom[pos] = node->pos;
            p->data->f_value = p->data->f_value - (p->data->g_value - ng_value);
            p->data->g_value = ng_value;
            p->data->dir = dir;
            fibheap_decrease(open_set, p);
        }
    }
}


static int jump_prune(struct heap *open_set, int end, int pos, unsigned char dir,
            Map *m, struct node_data *node) {
    int w = m->width;
    int h = m->height;
    int len = w * h;
    int next_pos = get_next_pos(pos, dir, w, h);
    // printf("next_pos:%d\n", next_pos);
    if (!map_walkable(m, next_pos)) {
        return 0;
    }
    if (next_pos == end) {
        put_in_open_set(open_set, m, next_pos, len, node, dir);
        return 1;
    }
    if (force_dir(next_pos, dir, m) != EMPTY_DIRECTIONSET) {
        put_in_open_set(open_set, m, next_pos, len, node, dir);
        return 0;
    }
    if (dir_is_diagonal(dir)) {
        int i;
        i = jump_prune(open_set, end, next_pos, (dir + 7) % 8, m, node);
        if (i == 1) {
            return 1;
        }
        i = jump_prune(open_set, end, next_pos, (dir + 1) % 8, m, node);
        if (i == 1) {
            return 1;
        }
    }
    return jump_prune(open_set, end, next_pos, dir, m, node);
}

static inline int compare(struct node_data* old, struct node_data* new) {
    if (new->f_value < old->f_value) {
        return 1;
    } else {
        return -1;
    }
}

int jps_find_path(Map *m) {
    int len = m->width * m->height;
    memset(&m->m[BITSLOT(len) + 1], 0, (BITSLOT(len) + 1) * sizeof(m->m[0]));
    memset(m->comefrom, -1, len * sizeof(int));
    memset(m->open_set_map, 0, len * sizeof(struct heap_node *));
    if (m->start == m->end) {
        return m->end;
    }
    if (m->mark_connected && (m->connected[m->start] != m->connected[m->end])) {
        return -1;
    }
    struct heap *open_set = fibheap_init(len, compare);
    struct node_data *node = construct(m, m->start, 0, NO_DIRECTION);
    m->open_set_map[m->start] = fibheap_insert(open_set, node);;
    while ((node = fibheap_pop(open_set))) {
        m->open_set_map[node->pos] = NULL;
        BITSET(m->m, (BITSLOT(len) + 1) * CHAR_BIT + node->pos);

        if (node->pos == m->end) {
            fibheap_destroy(open_set);
            return node->pos;
        }
        unsigned char cur_dir = node->dir;
        unsigned char check_dirs = natural_dir(node->pos, cur_dir, m) | force_dir(node->pos, cur_dir, m);
        unsigned char dir = next_dir(&check_dirs);
        while (dir != NO_DIRECTION) {
            if (jump_prune(open_set, m->end, node->pos, dir, m, node) == 1) { // found end
                break;
            }
            dir = next_dir(&check_dirs);
        }
    }
    fibheap_destroy(open_set);
    return -1;
}
