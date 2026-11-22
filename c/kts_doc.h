/* What the shim's translation units share: the flattened document. */
#ifndef KTS_DOC_H
#define KTS_DOC_H

#include <stdint.h>

#include "kts.h"
#include "tree_sitter/api.h"

struct KtsDoc {
  const TSLanguage *language;
  TSTree *tree;
  char *src;
  int64_t count;
  /* Per node, in preorder. */
  const void **id;
  uint16_t *symbol;
  uint8_t *leaf;
  uint32_t *descendants;
  uint32_t *start_row;
  uint32_t *end_row;
  uint32_t *end_col;
  /* Node id -> preorder index, open addressing, built on the first
   * query run. */
  int64_t slots;
  const void **slot_id;
  int64_t *slot_index;
  /* Captures of the last query run: capture id and preorder index. */
  int64_t captures;
  int64_t *capture_id;
  int64_t *capture_node;
};

const TSLanguage *kts_language_named(const char *name);
void kts_forget_captures(KtsDoc *d);
void kts_forget_index(KtsDoc *d);

#endif
