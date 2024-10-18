#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "fibheap.h"



#define CHECK_MALLOC(X) { \
        if((X)==NULL) { \
            fprintf(stderr, \
                "fib_heap.c: Error allocating memory\n"); \
            exit(1); \
        }; }

#define CHECK_INPUT(X, M) { \
        if(!(X)) {\
            fprintf(stderr, "fib_heap.c: %s\n", (M)); \
            exit(1); \
        }; }

static double LOG2(double n)
{
    return log(n)/log(2);
}

static void
exchange_right_node(struct heap_node *a, struct heap_node *b)
{
    struct heap_node *temp;
    CHECK_INPUT(a != NULL, "dblink_list_concat: a==NULL");
    CHECK_INPUT(b != NULL, "dblink_list_concat: b==NULL");

    temp = a->right;
    a->right = b->right;
    b->right->left = a;
    b->right = temp;
    temp->left = b;
}

struct heap *
fibheap_init(int max, int (*compr)(struct node_data *, struct node_data *))
{
    struct heap *H = (struct heap *)malloc(sizeof(struct heap));
    CHECK_MALLOC(H);
    CHECK_INPUT(max > 0, "fibheap_init: max has to be positive");
    H->the_one = NULL;
    H->cons_array = (struct heap_node **)malloc((LOG2(max)+2) *  sizeof(struct heap_node *));
    CHECK_MALLOC(H->cons_array);
    H->node_num = 0;
    H->max = max;
    H->compr = compr;
    return H;
}

struct heap_node *
fibheap_insert(struct heap *H, struct node_data *d)
{
    struct heap_node *node = (struct heap_node *)malloc(sizeof(struct heap_node));
    CHECK_MALLOC(node);
    CHECK_INPUT(H != NULL, "fibheap_insert: H==NULL");
    CHECK_INPUT(H->node_num<H->max, "fibheap_insert: Fibonacci Heap Overflow");

    node->data = d;
    node->degree = 0;
    node->marked = 0;
    node->parent = NULL;
    node->child = NULL;

    if ((H->the_one) == NULL) {
        node->left = node;
        node->right = node;
        H->the_one = node;
    } else {
        node->left = H->the_one->left;
        node->right = H->the_one;
        H->the_one->left->right = node;
        H->the_one->left = node;
        if (H->compr(H->the_one->data, node->data) > 0)
            H->the_one = node;
    }
    H->node_num++;

    return node;
}

static void
fibheap_link(struct heap_node *y, struct heap_node *x)
{
    struct heap_node *temp;

    y->left->right = y->right;
    y->right->left = y->left;

    y->parent = x;
    if (x->child == NULL) {
        x->child = y;
        y->left = y;
        y->right = y;
    } else {
        temp = x->child->right;
        x->child->right = y;
        y->left = x->child;
        temp->left = y;
        y->right = temp;
    }

    (x->degree)++;
    y->marked = 0;
}

static void
fibheap_consolidate(struct heap *H)
{
    int D, i, d;
    struct heap_node *x, *w, *y, *temp, *new_one;

    if (H->node_num == 0) {
        free(H->the_one);
        H->the_one = NULL;
        return;
    }

    D = LOG2(H->node_num);
    for (i = 0; i <= D; i++) {
        H->cons_array[i] = NULL;
    }

    w = H->the_one->right;
    new_one = w;
    while (w != H->the_one) {
        x = w;
        d = x->degree;
        while ((d <= D) && (H->cons_array[d] != NULL)) {
            y = H->cons_array[d];
            if ((H->compr)(x->data, y->data) > 0) {
                temp = x;
                x = y;
                y = temp;
            }
            if (w == y) {
                w = w->left;
            }
            fibheap_link(y, x);
            H->cons_array[d] = NULL;
            d++;
        }
        H->cons_array[d] = x;
        if ((H->compr)(x->data, new_one->data) <= 0) {
            new_one = x;
        }
        w = w->right;
    }

    H->the_one->left->right = H->the_one->right;
    H->the_one->right->left = H->the_one->left;
    free(H->the_one);
    H->the_one = new_one;
}

struct node_data *
fibheap_pop(struct heap *H)
{
    struct node_data *ret;
    int i;
    CHECK_INPUT(H != NULL, "fibheap_pop: H==NULL");

    if (H->the_one == NULL)
        return NULL;

    ret = H->the_one->data;

    for (i = 0; i < H->the_one->degree; i++) {
        H->the_one->child->parent = NULL;
        H->the_one->child = H->the_one->child->right;
    }

    if (H->the_one->child != NULL) {
        exchange_right_node(H->the_one, H->the_one->child);
    }
    H->node_num--;
    fibheap_consolidate(H);

    return ret;
}

static void
fibheap_cut(struct heap *H, struct heap_node *x, struct heap_node *y)
{
    (y->degree)--;
    if (y->degree == 0) {
        y->child = NULL;
    } else {
        y->child = x->right;
        x->left->right = x->right;
        x->right->left = x->left;
    }

    x->right = x;
    x->left = x;
    x->parent = NULL;
    x->marked = 0;
    exchange_right_node(H->the_one, x);
}

static void
fibheap_casc_cut(struct heap *H, struct heap_node *y)
{
    struct heap_node *z = y->parent;
    if (z == NULL) {
        return;
    }
    if (!(y->marked)) {
        y->marked = 1;
        return;
    }
    fibheap_cut(H, y, z);
    return fibheap_casc_cut(H, z);
}

void
fibheap_increase(struct heap *H, struct heap_node *node)
{
    struct heap_node *y;
    CHECK_INPUT(H != NULL, "fibheap_increase: H==NULL");
    CHECK_INPUT(node != NULL, "fibheap_increase: node==NULL");

    y = node->parent;
    if (y != NULL && ((H->compr)(y->data, node->data) > 0)) {
        fibheap_cut(H, node, y);
        fibheap_casc_cut(H, y);
    }
    if ((H->compr)(H->the_one->data, node->data) > 0) {
        H->the_one = node;
    }
}

void
fibheap_decrease(struct heap *H, struct heap_node *node)
{
    int i;
    struct heap_node *y;
    CHECK_INPUT(H != NULL, "fibheap_decrease: H==NULL");
    CHECK_INPUT(node != NULL, "fibheap_decrease: node==NULL");

    /* concat node's childs with the root list */
    for (i = 0; i < node->degree; i++) {
        node->child->parent = NULL;
        node->child = node->child->right;
    }
    if (node->child != NULL) {
        exchange_right_node(H->the_one, node->child);
    }
    node->child = NULL;
    node->degree = 0;

    /* cut the node */
    y = node->parent;
    if (y != NULL) {
        fibheap_cut(H, node, y);
        fibheap_casc_cut(H, y);
    } else if (H->the_one == node) { /* find then new the_one */
        y = node->right;
        while (y != node) {
            if ((H->compr)(node->data, y->data) > 0) {
                H->the_one = y;
            }
            y = y->right;
        }
    }
}

static void
fibheap_destroy_rec(struct heap_node *node)
{
    struct heap_node *start = node;

    if (node == NULL) {
        return;
    }

    do {
        fibheap_destroy_rec(node->child);
        node = node->right;
        free(node->left->data);
        free(node->left);
    } while (node != start);
}

void
fibheap_destroy(struct heap *H)
{
    CHECK_INPUT(H != NULL, "fibheap_destroy: H==NULL");

    fibheap_destroy_rec(H->the_one);
    free(H->cons_array);
    free(H);
}
