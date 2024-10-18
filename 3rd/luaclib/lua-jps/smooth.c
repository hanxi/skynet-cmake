
#include "smooth.h"
#include "map.h"

int find_line_obstacle(Map* m, float x1, float y1, float x2, float y2) {
    if (!map_walkable(m, xy2pos(m, (int)x1, (int)y1))) {
        return xy2pos(m, (int)x1, (int)y1);
    }
    if(!map_walkable(m, xy2pos(m, (int)x2, (int)y2))) {
        return xy2pos(m, (int)x2, (int)y2);
    }
    float k = (y2 - y1) / (x2 - x1);

    int min_x = x1 < x2 ? (int)x1 : (int)x2;
    int max_x = x1 < x2 ? (int)x2 : (int)x1;
    int min_y = y1 < y2 ? (int)y1 : (int)y2;
    int max_y = y1 < y2 ? (int)y2 : (int)y1;

    int x, y;
    // printf("find_line_obstacle %d %d\n", min_x, max_x);
    for (x = min_x + 1; x <= max_x; ++x) {
        y = (int)(k * ((float)x - x1) + y1);
        if (!map_walkable(m, xy2pos(m, x, y))) {
            return xy2pos(m, x, y);
        }
        if (!map_walkable(m, xy2pos(m, x - 1, y))) {
            return xy2pos(m, x - 1, y);
        }
    }

    for (y = min_y + 1; y <= max_y; ++y) {
        x = (int)((y - y1) / k + x1);
        if (!map_walkable(m, xy2pos(m, x, y))) {
            return xy2pos(m, x, y);
        }
        if (!map_walkable(m, xy2pos(m, x, y - 1))) {
            return xy2pos(m, x, y - 1);
        }
    }

    return -1;
}

void smooth_path(Map* m) {
    int x1, y1, x2, y2;
    for (int i = m->ipath_len - 1; i >= 0; i--) {
        for (int j = 0; j < i - 1; j++) {
            pos2xy(m, m->ipath[i], &x1, &y1);
            pos2xy(m, m->ipath[j], &x2, &y2);
            // printf("check (%d)%d <=> (%d)%d\n", i, m->ipath[i], j, m->ipath[j]);
            if (find_line_obstacle(m, x1 + 0.5, y1 + 0.5, x2 + 0.5,
                                    y2 + 0.5) < 0) {
                int offset = i - j - 1;
                // printf("merge (%d) to (%d) offset:%d\n", i, j, offset);
                for (int k = j + 1; k <= m->ipath_len - 1 - offset; k++) {
                    m->ipath[k] = m->ipath[k + offset];
                    // printf("%d <= %d\n", k, k + offset);
                }
                m->ipath_len -= offset;
                i = j + 1;
                break;
            }
        }
    }
}
