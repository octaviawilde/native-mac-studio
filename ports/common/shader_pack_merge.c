// Adds shaders or pipelines from a pack file to a player's cache file. Only ever adds: records the
// player already has are kept as they are, and the result replaces the file atomically.
// Usage: shader_pack_merge <xsh|xpso> <pack file> <cache file>
//   .xsh:  8-byte header, then records of u64 hash, u32 dword count (top bit = stage), ucode
//   .xpso: 12-byte header, then 66-byte records starting with a u64 hash
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { uint8_t *data; size_t size; } Blob;

static int read_file(const char *path, Blob *b) {
  b->data = NULL; b->size = 0;
  FILE *f = fopen(path, "rb");
  if (!f) return 0;
  fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
  b->data = malloc(n > 0 ? (size_t)n : 1);
  b->size = fread(b->data, 1, (size_t)n, f);
  fclose(f);
  return b->size == (size_t)n;
}

// Size of the complete record at `o`, or 0 if the file ends or is damaged there.
static size_t record_size(const Blob *b, size_t o, int is_shader) {
  if (!is_shader) return o + 66 <= b->size ? 66 : 0;
  if (o + 12 > b->size) return 0;
  uint32_t c; memcpy(&c, b->data + o + 8, 4);
  size_t n = 12 + (size_t)(c & 0x7fffffffu) * 4;
  return o + n <= b->size ? n : 0;
}

static uint64_t *seen; static size_t seen_cap;

static int seen_add(uint64_t h) {  // returns 1 if new
  uint64_t key = h ? h : 1;
  for (size_t i = (size_t)(key * 0x9E3779B97F4A7C15ull) & (seen_cap - 1);; i = (i + 1) & (seen_cap - 1)) {
    if (seen[i] == key) return 0;
    if (!seen[i]) { seen[i] = key; return 1; }
  }
}

int main(int argc, char **argv) {
  if (argc != 4) return 2;
  int is_shader = strcmp(argv[1], "xsh") == 0;
  size_t header = is_shader ? 8 : 12;
  Blob pack, cache;
  if (!read_file(argv[2], &pack) || pack.size < header) return 3;
  int have_cache = read_file(argv[3], &cache) && cache.size >= header;
  // A cache from a different engine version can't be merged into; leave it untouched.
  if (have_cache && memcmp(pack.data, cache.data, header) != 0) { fprintf(stderr, "header differs\n"); return 4; }

  seen_cap = 1; while (seen_cap < (pack.size + cache.size) / 4 + 64) seen_cap <<= 1;
  seen = calloc(seen_cap, sizeof *seen);

  char tmp[4096];
  if (snprintf(tmp, sizeof tmp, "%s.merging", argv[3]) >= (int)sizeof tmp) return 5;
  FILE *out = fopen(tmp, "wb");
  if (!out) return 5;
  fwrite(pack.data, 1, header, out);
  size_t kept = 0, added = 0, o;
  if (have_cache) {
    for (o = header;;) {
      size_t n = record_size(&cache, o, is_shader);
      if (!n) break;
      uint64_t h; memcpy(&h, cache.data + o, 8);
      if (seen_add(h)) { fwrite(cache.data + o, 1, n, out); kept++; }
      o += n;
    }
  }
  for (o = header;;) {
    size_t n = record_size(&pack, o, is_shader);
    if (!n) break;
    uint64_t h; memcpy(&h, pack.data + o, 8);
    if (seen_add(h)) { fwrite(pack.data + o, 1, n, out); added++; }
    o += n;
  }
  if (fclose(out) != 0 || rename(tmp, argv[3]) != 0) { remove(tmp); return 6; }
  printf("%s: kept %zu, added %zu\n", argv[1], kept, added);
  return 0;
}
