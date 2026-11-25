#include <stdlib.h>
#include <string.h>

#include "kts_doc.h"

const TSLanguage *tree_sitter_rust(void);
const TSLanguage *tree_sitter_kaikai(void);
const TSLanguage *tree_sitter_elixir(void);

const TSLanguage *kts_language_named(const char *name) {
  if (strcmp(name, "rust") == 0) return tree_sitter_rust();
  if (strcmp(name, "kaikai") == 0) return tree_sitter_kaikai();
  if (strcmp(name, "elixir") == 0) return tree_sitter_elixir();
  return NULL;
}

static void record(KtsDoc *d, TSNode n, int64_t i) {
  TSPoint end = ts_node_end_point(n);
  d->id[i] = n.id;
  d->symbol[i] = ts_node_symbol(n);
  d->leaf[i] = ts_node_child_count(n) == 0;
  d->descendants[i] = ts_node_descendant_count(n);
  d->start_row[i] = ts_node_start_point(n).row;
  d->end_row[i] = end.row;
  d->end_col[i] = end.column;
}

/* Preorder walk with a cursor, recording every node. */
static void flatten(KtsDoc *d) {
  TSTreeCursor c = ts_tree_cursor_new(ts_tree_root_node(d->tree));
  int64_t i = 0;
  int more = 1;
  while (more) {
    record(d, ts_tree_cursor_current_node(&c), i++);
    if (ts_tree_cursor_goto_first_child(&c)) continue;
    while (more && !ts_tree_cursor_goto_next_sibling(&c)) more = ts_tree_cursor_goto_parent(&c);
  }
  ts_tree_cursor_delete(&c);
}

/* Sized once from the node count: no allocation per node. */
static int allocate(KtsDoc *d) {
  size_t n = (size_t)d->count;
  d->id = malloc(sizeof *d->id * n);
  d->symbol = malloc(sizeof *d->symbol * n);
  d->leaf = malloc(sizeof *d->leaf * n);
  d->descendants = malloc(sizeof *d->descendants * n);
  d->start_row = malloc(sizeof *d->start_row * n);
  d->end_row = malloc(sizeof *d->end_row * n);
  d->end_col = malloc(sizeof *d->end_col * n);
  return d->id && d->symbol && d->leaf && d->descendants && d->start_row && d->end_row && d->end_col;
}

static TSTree *parse_tree(const TSLanguage *language, const char *src, size_t len) {
  TSParser *parser = ts_parser_new();
  TSTree *tree = ts_parser_set_language(parser, language) ? ts_parser_parse_string(parser, NULL, src, (uint32_t)len) : NULL;
  ts_parser_delete(parser);
  return tree;
}

KtsDoc *kts_parse(const char *lang, const char *src) {
  KtsDoc *d = calloc(1, sizeof *d);
  if (!d) return NULL;
  const TSLanguage *language = kts_language_named(lang);
  size_t len = strlen(src);
  d->src = malloc(len + 1);
  d->tree = language && d->src ? parse_tree(language, src, len) : NULL;
  if (!d->tree) return d;
  memcpy(d->src, src, len + 1);
  d->language = language;
  return d;
}

/* The flattened arrays, built the first time something asks for a node
 * by index: a query alone does not need them. */
int kts_flat(KtsDoc *d) {
  if (d->id) return 1;
  if (!d->language) return 0;
  d->count = ts_node_descendant_count(ts_tree_root_node(d->tree));
  if (!allocate(d)) {
    d->count = 0;
    return 0;
  }
  flatten(d);
  return 1;
}

int kts_ok(KtsDoc *d) { return d && d->language != NULL; }

void kts_free(KtsDoc *d) {
  if (!d) return;
  if (d->tree) ts_tree_delete(d->tree);
  kts_forget_captures(d);
  kts_forget_index(d);
  free(d->src);
  free(d->id);
  free(d->symbol);
  free(d->leaf);
  free(d->descendants);
  free(d->start_row);
  free(d->end_row);
  free(d->end_col);
  free(d);
}

int64_t kts_count(KtsDoc *d) { return kts_flat(d) ? d->count : 0; }
int64_t kts_symbol(KtsDoc *d, int64_t i) { return d->symbol[i]; }
int kts_leaf(KtsDoc *d, int64_t i) { return d->leaf[i]; }
int64_t kts_descendants(KtsDoc *d, int64_t i) { return d->descendants[i]; }
int64_t kts_start_row(KtsDoc *d, int64_t i) { return d->start_row[i]; }
int64_t kts_end_row(KtsDoc *d, int64_t i) { return d->end_row[i]; }
int64_t kts_end_col(KtsDoc *d, int64_t i) { return d->end_col[i]; }

int64_t kts_symbol_count(const char *lang) {
  const TSLanguage *language = kts_language_named(lang);
  return language ? ts_language_symbol_count(language) : 0;
}

const char *kts_symbol_name(const char *lang, int64_t symbol) {
  const TSLanguage *language = kts_language_named(lang);
  const char *name = language ? ts_language_symbol_name(language, (TSSymbol)symbol) : NULL;
  return name ? name : "";
}
