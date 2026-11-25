/* km2's shim over tree-sitter: a parsed file flattened into arrays,
 * reached from kaikai through integers, strings and one opaque handle. */
#ifndef KTS_H
#define KTS_H

#include <stdint.h>

typedef struct KtsDoc KtsDoc;

KtsDoc *kts_parse(const char *lang, const char *src);
int kts_ok(KtsDoc *d);
void kts_free(KtsDoc *d);

int64_t kts_count(KtsDoc *d);
int64_t kts_symbol(KtsDoc *d, int64_t i);
int kts_leaf(KtsDoc *d, int64_t i);
int64_t kts_descendants(KtsDoc *d, int64_t i);
int64_t kts_start_row(KtsDoc *d, int64_t i);
int64_t kts_end_row(KtsDoc *d, int64_t i);
int64_t kts_end_col(KtsDoc *d, int64_t i);

typedef struct KtsQuery KtsQuery;

KtsQuery *kts_query_new(const char *lang, const char *src);
int64_t kts_query_error(KtsQuery *q);
void kts_query_free(KtsQuery *q);
int64_t kts_capture_count(KtsQuery *q);
const char *kts_capture_name(KtsQuery *q, int64_t id);

int64_t kts_run(KtsDoc *d, KtsQuery *q);
int64_t kts_capture_id(KtsDoc *d, int64_t k);
int64_t kts_capture_node(KtsDoc *d, int64_t k);
int64_t kts_capture_start_byte(KtsDoc *d, int64_t k);
int64_t kts_capture_end_byte(KtsDoc *d, int64_t k);
int64_t kts_capture_start_row(KtsDoc *d, int64_t k);

int64_t kts_symbol_count(const char *lang);
const char *kts_symbol_name(const char *lang, int64_t symbol);

#endif
