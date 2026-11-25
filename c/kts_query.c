#include <stdlib.h>
#include <string.h>

#include "kts_doc.h"

struct KtsQuery {
  TSQuery *query;
  int64_t error;
};

KtsQuery *kts_query_new(const char *lang, const char *src) {
  KtsQuery *q = calloc(1, sizeof *q);
  if (!q) return NULL;
  const TSLanguage *language = kts_language_named(lang);
  uint32_t offset = 0;
  TSQueryError kind = TSQueryErrorNone;
  q->query = language ? ts_query_new(language, src, (uint32_t)strlen(src), &offset, &kind) : NULL;
  q->error = q->query ? -1 : (int64_t)offset;
  return q;
}

int64_t kts_query_error(KtsQuery *q) { return q->error; }

void kts_query_free(KtsQuery *q) {
  if (!q) return;
  if (q->query) ts_query_delete(q->query);
  free(q);
}

int64_t kts_capture_count(KtsQuery *q) { return q->query ? ts_query_capture_count(q->query) : 0; }

const char *kts_capture_name(KtsQuery *q, int64_t id) {
  uint32_t len = 0;
  return q->query ? ts_query_capture_name_for_id(q->query, (uint32_t)id, &len) : "";
}

static int64_t slot_of(const KtsDoc *d, const void *id) {
  uint64_t h = (uint64_t)(uintptr_t)id;
  h ^= h >> 33;
  h *= 0xff51afd7ed558ccdULL;
  h ^= h >> 33;
  int64_t s = (int64_t)(h & (uint64_t)(d->slots - 1));
  while (d->slot_id[s] && d->slot_id[s] != id) s = (s + 1) & (d->slots - 1);
  return s;
}

static void index_nodes(KtsDoc *d) {
  d->slots = 1;
  while (d->slots < 2 * d->count) d->slots <<= 1;
  d->slot_id = calloc((size_t)d->slots, sizeof *d->slot_id);
  d->slot_index = malloc(sizeof *d->slot_index * (size_t)d->slots);
  for (int64_t i = 0; i < d->count; i++) {
    int64_t s = slot_of(d, d->id[i]);
    d->slot_id[s] = d->id[i];
    d->slot_index[s] = i;
  }
}

void kts_forget_index(KtsDoc *d) {
  free(d->slot_id);
  free(d->slot_index);
  d->slot_id = NULL;
  d->slot_index = NULL;
}

void kts_forget_captures(KtsDoc *d) {
  free(d->capture_id);
  free(d->capture_node);
  d->capture_id = NULL;
  d->capture_node = NULL;
  d->captures = 0;
}

/* The node of capture `id` in a match, when the match has one. */
static int captured(const TSQueryMatch *m, uint32_t id, TSNode *node) {
  for (uint16_t j = 0; j < m->capture_count; j++) {
    if (m->captures[j].index == id) {
      *node = m->captures[j].node;
      return 1;
    }
  }
  return 0;
}

static int text_is(const KtsDoc *d, TSNode n, const char *s, uint32_t len) {
  uint32_t a = ts_node_start_byte(n);
  return ts_node_end_byte(n) - a == len && memcmp(d->src + a, s, len) == 0;
}

/* The text an operand of a predicate stands for: a string, or the text
 * of a captured node. */
static int operand(const KtsDoc *d, const TSQuery *q, const TSQueryMatch *m, TSQueryPredicateStep step,
                   const char **s, uint32_t *len) {
  if (step.type == TSQueryPredicateStepTypeString) {
    *s = ts_query_string_value_for_id(q, step.value_id, len);
    return 1;
  }
  TSNode n;
  if (step.type != TSQueryPredicateStepTypeCapture || !captured(m, step.value_id, &n)) return 0;
  *s = d->src + ts_node_start_byte(n);
  *len = ts_node_end_byte(n) - ts_node_start_byte(n);
  return 1;
}

/* One `#eq?` or `#not-eq?` predicate, starting at step `p`. */
static int holds(const KtsDoc *d, const TSQuery *q, const TSQueryMatch *m, const TSQueryPredicateStep *p) {
  uint32_t len = 0;
  const char *op = ts_query_string_value_for_id(q, p[0].value_id, &len);
  int eq = strcmp(op, "eq?") == 0;
  TSNode left;
  const char *right;
  uint32_t right_len;
  if (!eq && strcmp(op, "not-eq?") != 0) return 0;
  if (p[1].type != TSQueryPredicateStepTypeCapture || !captured(m, p[1].value_id, &left)) return 0;
  if (!operand(d, q, m, p[2], &right, &right_len)) return 0;
  return eq == text_is(d, left, right, right_len);
}

/* Whether a match satisfies its pattern's predicates, which the C
 * library leaves to its caller. A predicate the shim does not know
 * rejects the match, so a query never means more than it says. */
static int satisfies(const KtsDoc *d, const TSQuery *q, const TSQueryMatch *m) {
  uint32_t steps = 0;
  const TSQueryPredicateStep *p = ts_query_predicates_for_pattern(q, m->pattern_index, &steps);
  uint32_t i = 0;
  while (i < steps) {
    if (i + 3 > steps || !holds(d, q, m, p + i)) return 0;
    while (i < steps && p[i].type != TSQueryPredicateStepTypeDone) i++;
    i++;
  }
  return 1;
}

static void keep(KtsDoc *d, int64_t *cap, uint32_t id, TSNode node) {
  if (d->captures == *cap) {
    *cap *= 2;
    d->capture_id = realloc(d->capture_id, sizeof *d->capture_id * (size_t)*cap);
    d->capture_node = realloc(d->capture_node, sizeof *d->capture_node * (size_t)*cap);
  }
  d->capture_id[d->captures] = id;
  d->capture_node[d->captures] = node;
  d->captures++;
}

/* Runs `q` over the document and keeps its captures, in match order. */
int64_t kts_run(KtsDoc *d, KtsQuery *q) {
  kts_forget_captures(d);
  if (!d->language || !q->query) return 0;
  int64_t cap = 16;
  d->capture_id = malloc(sizeof *d->capture_id * (size_t)cap);
  d->capture_node = malloc(sizeof *d->capture_node * (size_t)cap);
  TSQueryCursor *cursor = ts_query_cursor_new();
  TSQueryMatch m;
  ts_query_cursor_exec(cursor, q->query, ts_tree_root_node(d->tree));
  while (ts_query_cursor_next_match(cursor, &m)) {
    if (!satisfies(d, q->query, &m)) continue;
    for (uint16_t j = 0; j < m.capture_count; j++) keep(d, &cap, m.captures[j].index, m.captures[j].node);
  }
  ts_query_cursor_delete(cursor);
  return d->captures;
}

int64_t kts_capture_id(KtsDoc *d, int64_t k) { return d->capture_id[k]; }
int64_t kts_capture_node(KtsDoc *d, int64_t k) {
  if (!kts_flat(d)) return -1;
  if (!d->slot_id) index_nodes(d);
  return d->slot_index[slot_of(d, d->capture_node[k].id)];
}

int64_t kts_capture_start_byte(KtsDoc *d, int64_t k) { return ts_node_start_byte(d->capture_node[k]); }
int64_t kts_capture_end_byte(KtsDoc *d, int64_t k) { return ts_node_end_byte(d->capture_node[k]); }
int64_t kts_capture_start_row(KtsDoc *d, int64_t k) { return ts_node_start_point(d->capture_node[k]).row; }
