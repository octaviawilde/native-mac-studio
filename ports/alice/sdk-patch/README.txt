Alice SDK patch
===============

rexglue-sdk-alice.patch holds our ReXGlue SDK changes for Alice as a diff on top of
tekken6-recomp's SDK patch. It is not a diff against a clean SDK.

Apply in this order:
  1. rexglue-sdk at the commit in ../../tekken6/sdk-patch/BASE.txt
  2. patches/rexglue/0001-tekken6-runtime.patch from
     https://github.com/mahmoud-mess/tekken6-recomp at commit 3efad760bf2a
     (not included here: that project has no license file; see ../../tekken6/UPSTREAM.txt)
  3. git apply rexglue-sdk-alice.patch   (new files are inside it)

Use it INSTEAD of ../../tekken6/sdk-patch/rexglue-sdk-mac.patch, not after it: it already
contains those changes.

What it adds beyond the Tekken delta: the shader-stutter fix. skullburglar's 0008 (pipelines
built on worker threads, background shader precompile; BSD-3-Clause, see
THIRD_PARTY_NOTICES.md), the header parts of its 0003 that 0008 needs, and our
async_shader_skip_new_draws: draws whose pipeline is still being built are skipped instead of
compiling a placeholder on the GPU thread.
Measured (empty caches, same checkpoint): load hitch 3.6 s -> 0.4 s, gameplay hitches up to
0.57 s -> 0.08 s.

One difference from our own build tree: step 2 adds tools/build_fused_resolve_shader.py
(a shader build helper, not used by the build), which our tree did not have. This patch
leaves it in place.
