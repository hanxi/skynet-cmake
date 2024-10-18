#ifndef __FIB_HEAP_H__
#define __FIB_HEAP_H__ 0

struct node_data
{
    int pos;
    int g_value;
    int f_value;
    unsigned char dir;
};

struct heap_node {
    struct node_data *data;
    int degree;
    char marked;
    struct heap_node *parent;
    struct heap_node *child;
    struct heap_node *left;
    struct heap_node *right;
};

struct heap {
    struct heap_node *the_one;
    struct heap_node **cons_array;
    int (*compr) (struct node_data *, struct node_data *);
    int node_num;
    int max;
};

struct heap *
fibheap_init(int max, int (*compr)(struct node_data *, struct node_data *));

struct heap_node *
fibheap_insert(struct heap *H, struct node_data *d);

struct node_data *
fibheap_pop(struct heap *H);

void
fibheap_decrease(struct heap *H, struct heap_node *node);

void
fibheap_destroy(struct heap *H);

#endif /* __FIB_HEAP_H__ */
