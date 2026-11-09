# Third-party notices

The MIT license in `LICENSE` covers only what the Native Mac Studio contributors wrote.
Everything below belongs to others and keeps its own license. No game data, recompiled game
code or box art is in this repository.

## Summary

| What here | Based on | License that applies |
|---|---|---|
| `ports/tekken6/sdk-patch/rexglue-sdk-mac.patch`, `ports/alice/sdk-patch/rexglue-sdk-alice.patch` | [ReXGlue SDK](https://github.com/rexglue/rexglue-sdk) (derived from Xenia) | BSD-3-Clause |
| Parts of `ports/alice/sdk-patch/rexglue-sdk-alice.patch`; `ports/alice/CMakePresets.json` | [skullburglar](https://github.com/nlwstein/skullburglar) | BSD-3-Clause |
| `ports/alice/CMakeLists.txt`, `ports/alice/src/`, `ports/alice/alice_manifest.toml` | Started from the ReXGlue SDK `rexglue init` templates | BSD-3-Clause |
| `ports/tekken6/tekken6-recomp-mac.patch` and the context lines of the two SDK patches | [tekken6-recomp](https://github.com/mahmoud-mess/tekken6-recomp) | No license; not redistributed here (see below) |
| `ports/harry-potter-cos/psxrecomp-patches/` | [psxrecomp](https://github.com/mstan/psxrecomp) | PolyForm Noncommercial 1.0.0 |
| `ports/common/spirv-cross-ubo-as-device.patch` | SPIRV-Cross (Khronos Group) | Apache-2.0 |
| Fonts (`fonts/`, `arcade/assets/fonts/`, `ports/harry-potter-cos/app/fonts/`) | see below | SIL Open Font License 1.1 |

## ReXGlue SDK (BSD-3-Clause)

The Tekken 6 and Alice SDK patches change rexglue-sdk, starting from the commit named in
`ports/tekken6/sdk-patch/BASE.txt` (with tekken6-recomp's SDK patch applied first; see below).
The Alice project files started from the SDK's `rexglue init` templates. A patch contains lines of the original source and is a
modification of it, so the ReXGlue license applies to these patches. BSD-3-Clause allows
redistributing modified source as long as the copyright notice, the conditions and the
disclaimer are kept; they are reproduced here.

    Copyright (c) 2026, Tom Clay <tomc@tctechstuff.com>

    Portions of this software are derived from the Xenia project:
    Copyright (c) 2022, Ben Vanik and Xenia project contributors
    https://xenia.jp

    All rights reserved.

The BSD-3-Clause text is given once, under "BSD 3-Clause License text" below.

## skullburglar (BSD-3-Clause)

https://github.com/nlwstein/skullburglar

`ports/alice/sdk-patch/rexglue-sdk-alice.patch` includes skullburglar's ReXGlue SDK patch
`0008-async-pipelines-background-precompile` (pipelines built on worker threads, background
shader precompile) and the header parts of `0003-vulkan-hoist-shared-memory-uploads` that it
needs. `ports/alice/CMakePresets.json` is the same file as skullburglar's.

    BSD 3-Clause License

    Copyright (c) 2026, the Skullburglar contributors

skullburglar's license adds: "The patches in patches/rexglue-sdk/ modify the ReXGlue SDK and
are also covered by its license (BSD 3-Clause, Copyright (c) 2026, Tom Clay; portions derived
from the Xenia project)."

## BSD 3-Clause License text

Applies to the ReXGlue SDK and skullburglar material above, each under its own copyright line.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
       list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its
       contributors may be used to endorse or promote products derived from
       this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## tekken6-recomp (no license; not included)

https://github.com/mahmoud-mess/tekken6-recomp

The Tekken 6 port builds on this community project. It has no license file, so none of its
files are in this repository: not its build files, sources, config, manifest, tools, nor its
ReXGlue SDK patch (`patches/rexglue/0001-tekken6-runtime.patch`). You get them from its
repository at the commit named in `ports/tekken6/UPSTREAM.txt`.

What is here is only what we changed:

- `ports/tekken6/tekken6-recomp-mac.patch`: our edit to its `CMakeLists.txt`.
- `ports/tekken6/sdk-patch/rexglue-sdk-mac.patch` and
  `ports/alice/sdk-patch/rexglue-sdk-alice.patch`: our ReXGlue SDK changes, made as diffs on
  top of "SDK + their patch".

As with any patch, these diffs carry a few unchanged context lines, and some removed lines,
from the files they apply to; in places those lines come from tekken6-recomp's patch rather
than from the ReXGlue SDK. They are there only so the patch can be applied. If the author of
tekken6-recomp objects, contact us and we will rework them.

`ports/alice/CMakeLists.txt` and `ports/alice/src/` come from the ReXGlue SDK's own project
templates, not from tekken6-recomp. The step that copies the GPU plugin beside the binary
follows the same approach tekken6-recomp uses, written by us.

## psxrecomp (PolyForm Noncommercial 1.0.0)

https://github.com/mstan/psxrecomp, Copyright (c) 2026 Matthew Stanley.
License: https://polyformproject.org/licenses/noncommercial/1.0.0

The three patches in `ports/harry-potter-cos/psxrecomp-patches/` are changes to psxrecomp at
the commit named in `BASE.txt`. The license allows distributing the software and "making
changes and new works based on it", for noncommercial purposes only. These patches are
therefore offered under PolyForm Noncommercial 1.0.0, not under MIT, and may not be used
commercially. `ports/harry-potter-cos/psxrecomp-patches/LICENSE-NOTICE.md` says the same next
to the patches and carries the required notice. Commercial licensing: contact the licensor (see the psxrecomp repository).

## SPIRV-Cross (Apache-2.0)

`ports/common/spirv-cross-ubo-as-device.patch` changes `spirv_msl.cpp` from SPIRV-Cross
(file header: Copyright 2016-2021 The Brenwill Workshop Ltd.; Apache
License 2.0, https://www.apache.org/licenses/LICENSE-2.0). Apache-2.0 allows distributing
modifications if the license is included or referenced and changed files are marked as
changed; the patch itself is that marker (it adds the `REX_MSL_UBO_AS_DEVICE` switch).

## MoltenVK (Apache-2.0)

No MoltenVK code is in this repository. The build scripts bundle the MoltenVK library that
the ReXGlue SDK ships (Copyright The Brenwill Workshop Ltd., Apache License 2.0) into the
`.app` they produce. Anyone who shares such an app must include MoltenVK's license and
notices with it, along with the notices of the other libraries the SDK links (SDL3: zlib
license; Vulkan loader: Apache-2.0; and those listed in the SDK's `thirdparty/` folder).

## Fonts (SIL Open Font License 1.1)

Each font has its license text next to it.

| Font file | Copyright | License file |
|---|---|---|
| `fonts/anton-Anton-Regular.ttf` | 2020 The Anton Project Authors | `fonts/anton-OFL.txt` |
| `fonts/unifrakturmaguntia-UnifrakturMaguntia-Book.ttf` | 2010 j. 'mach' wust | `fonts/unifrakturmaguntia-OFL.txt` |
| `arcade/assets/fonts/RubikWetPaint-Regular.ttf` | 2020 The Rubik Filtered Project Authors | `arcade/assets/fonts/RubikWetPaint-OFL.txt` |
| `arcade/assets/fonts/Silkscreen-Regular.ttf`, `Silkscreen-Bold.ttf` | 2001 The Silkscreen Project Authors | `arcade/assets/fonts/Silkscreen-OFL.txt` |
| `ports/harry-potter-cos/app/fonts/CinzelDecorative-Bold.ttf` | 2012 Natanael Gama | `ports/harry-potter-cos/app/fonts/OFL.txt` |

## Trademarks

Tekken, Alice: Madness Returns, Harry Potter, Xbox and PlayStation are trademarks of their
owners. This project is not affiliated with or endorsed by them.
