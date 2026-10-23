# Limit Theory

Limit Theory is a now-cancelled open world space simulation game.

This repository is the game (not engine) code for the second generation of LT's development, when all work was migrated to C and Lua. For the older, C++/LTSL Limit Theory, see https://github.com/JoshParnell/ltheory-old.

![LT Screenshot](./res/tex2d/screenshot.png)

# Prerequisites

To build Limit Theory, you'll need a few standard developer tools. All of them are available to download for free.

- Python: https://www.python.org/downloads/
- Git: https://git-scm.com/downloads
- Git LFS: https://git-lfs.github.com/
- Visual Studio Community: https://visualstudio.microsoft.com/vs/
- CMake: https://cmake.org/download/

# Building

## Apple Silicon macOS

Use Apple's command-line Clang toolchain (Command Line Tools or Xcode), Python 3,
and CMake 3.13+. No Xcode project or IDE is needed.

```sh
brew install cmake pkg-config sdl2-compat glew freetype luajit lz4 bullet git-lfs luarocks
luarocks --lua-version=5.1 --lua-dir="$(brew --prefix luajit)" --tree="$(brew --prefix)" install luafilesystem 1.8.0-1
git submodule update --init --recursive
python3 configure.py configure -DPHX_AUDIO_BACKEND=NULL -DCMAKE_OSX_ARCHITECTURES=arm64
python3 configure.py build --parallel 8
python3 configure.py run LTheory
```

The default configuration is `RelWithDebInfo`, producing `bin/lt64` and
`bin/libphx64.dylib`. To use another configuration consistently with the helper,
set `CMAKE_BUILD_TYPE` in the environment for configure, build and run. The
launcher passes the actual engine filename to Lua's FFI loader, including any
configuration suffix. Homebrew dependencies must remain installed at runtime.

Audio is disabled by default on macOS: the silent backend preserves the public
audio functions without FMOD or sound-file loading. Other platforms retain FMOD
by default. Native macOS FMOD support is not implemented yet.

### Optional OSS audio (miniaudio)

```sh
python3 configure.py configure -DPHX_AUDIO_BACKEND=MINIAUDIO
python3 configure.py build --parallel 8
python3 configure.py run FMODTest
```

The existing `FMODTest` now uses the current backend-neutral Sound/Audio API and
the bundled assets (no new audio files). It starts the MP3 music loop at 20%
volume. Controls:

- **1 / 2:** MP3 one-shots; **3:** WAV one-shot.
- **M:** switch between MP3 and Vorbis (`Imperial_March.ogx`) music loops.
- **Space:** pause/resume; **R:** rewind; **P:** cycle pitch.
- **- / =:** decrease/increase volume.
- **WASD / right mouse drag:** move the blue listener relative to the emitters.
- **Escape:** exit and shut down audio.

No proprietary SDK or additional package installation is required. Miniaudio
and the Vorbis decoder are pinned and vendored in the engine. Manual testing on
Apple Silicon confirmed the audio test's playback, positional audio, controls,
and clean shutdown across the bundled MP3, WAV, and Vorbis assets.
NULL remains the default on macOS; select `-DPHX_AUDIO_BACKEND=NULL` to switch
back. An explicit backend overrides the old `PHX_AUDIO` cache value. FMOD remains
available on its original platforms through `-DPHX_AUDIO_BACKEND=FMOD`.

`python3 configure.py run LTheory` still launches the game with the selected
backend. The current gameplay has no active Sound playback calls, so use
`FMODTest` to check audibility rather than expecting a new in-game soundtrack.
Async loading stress, WAV export, and longer-running lifetimes remain to be tested.

LuaFileSystem must target LuaJIT's Lua 5.1 ABI, not the standalone Lua version
installed with LuaRocks. The command above installs it into Homebrew's prefix,
which this LuaJIT searches by default. Startup explicitly loads it before the
game's filesystem helpers. Optional JIT debugging modules are loaded on demand;
newer LuaJIT releases use their own standard dumper rather than the historical
custom `jit.dump2` implementation.

**Current verification:** arm64 compilation/linking, native library loading,
embedded LuaJIT/FFI, the silent audio lifecycle, Lua bootstrap/namespace loading,
and OpenGL context creation work. `LTheory` generated its world and remained in
the rendering loop for a 60-second smoke test without crashing. A manual launch
also confirmed basic interactive operation. Detailed visual fidelity, input, and
longer gameplay still need verification. Nonfatal warnings about inactive
automatic shader variables remain.

The macOS-only shader preamble selects GLSL 1.20 with
`GL_ARB_shader_texture_lod`; other platforms retain GLSL 1.30. Two small shared
correctness fixes avoid stale collision-cache pointers after reallocation and
avoid submitting textures/draws for font glyphs with empty bitmaps (e.g. spaces).

For runtime assets, run `git lfs install --local` and `git lfs pull` once per
checkout. These are unnecessary for compilation alone.

Engine development in this workspace uses the sibling `../libphx` repository.
The game still builds **its own** `libphx` submodule, not that sibling, and pins
the engine commit used for this port. Commit engine changes in the sibling
repository, fetch them into the submodule using its local `sibling` remote, and
advance the game's submodule pointer. These commits are local until published;
the original upstream submodule URL does not contain the macOS port.

## Manual GitHub builds

`.github/workflows/build.yml` builds the game and its exact pinned engine commit
with **MINIAUDIO / RelWithDebInfo** on these GitHub-hosted runners:

| Target | Runner | Toolchain |
| --- | --- | --- |
| Windows x64 | `windows-2022` | Visual Studio 2022 / MSVC |
| Linux x64 | `ubuntu-24.04` | GCC |
| macOS arm64 | `macos-15` | Apple Clang |

The only trigger is `workflow_dispatch`: pushes, pull requests and schedules do
not start builds. Each dispatch builds all three targets independently; no game
or audio is launched. Windows/Linux compilation still needs confirmation from
the first successful workflow run; a CI build is not a runtime-support guarantee.
There are no 32-bit, Intel macOS, or Linux/Windows arm64 jobs.

Jobs verify shell error propagation (including failures piped through `tee`),
binary architecture, and the pinned engine commit. Before packaging, a separate
process loads the engine shared library and calls `Engine_GetBits`, forcing
dependency resolution without initializing graphics/audio or launching the game.
Loader failures, native crashes, and timeouts fail the job. Successful jobs
therefore establish compilation, linking and basic library loading, not gameplay.

### Enabling and running

GitHub requires the workflow to exist on the repository's **default branch**
before it can be dispatched. If it only exists on `macos`, first publish the
workflow to the default branch (or deliberately change the default branch).
Then open **Actions → Build binaries → Run workflow**, selecting `macos`, or use:

```sh
gh workflow run build.yml --ref macos
gh run list --workflow build.yml
```

The game checkout uses the normal read-only GitHub token. The engine checkout
derives its GitHub repository from `.gitmodules` and uses the game's committed
gitlink SHA, not the latest engine branch. Both forks are currently public, so
no additional secret is required. If the engine becomes private, add a read-only
deploy key to that engine repository and save its private key as the game
repository Actions secret `LIBPHX_DEPLOY_KEY`. Do not commit the key. Checkout
verifies GitHub's SSH host key and does not persist credentials for build steps.

### Artifacts and limitations

Each job uploads a `ltheory-<platform>-miniaudio` artifact containing a `.tar.gz`
archive of the launcher, engine shared library, available debug symbols, and
build metadata. Windows also includes the dependency DLLs copied by CMake.
Tar preserves executable permissions when downloading through Actions.
Separate `diagnostics-<platform>` artifacts contain configuration/build logs and
compiler configuration, including on build failure. Retention is 14 days.

These are **compilation artifacts, not standalone game distributions**. They omit
Lua scripts and LFS assets; use them with the matching source checkout and
runtime dependencies. Linux/macOS system libraries are not bundled, macOS refers
to Homebrew libraries, and Windows needs the Visual C++ runtime. Builds are not
signed/notarized and do not define a tested minimum runtime OS version. No game
assets are downloaded during CI. No releases are published by the workflow.

For local workflow validation, use `actionlint .github/workflows/build.yml`.

## Original Windows instructions

With the above prerequisites installed, open a **Git Bash terminal**.

## Checking out the Repository

First, use `cd` to change directories to the place where you want to download LT.
- `cd ~/Desktop/<path where you want to put the LT source>`

Before doing any other `git` commands, make sure LFS is installed:
- `git lfs install`

You should see `Git LFS initialized` or a similar message. **Important**: if you forget to install and initialize Git LFS, most of the resources will probably be broken, and the whole process will likely fail in strange and mysterious ways. This is a common gotcha with projects that use LFS. Make sure you do the above step!

Now, you can download the repository:

- `git clone --recursive https://github.com/JoshParnell/ltheory.git ltheory`

## Compiling

Once you have the repository, the build process proceeds in two steps (as with other CMake builds): generating the build files, and then building. There is a Python script `configure.py` at the top level of the repository to help you do this easily.

From a terminal in the directory of the checked-out repository, run

- `python configure.py`

This runs CMake to generate the build files. Then, to compile,

- `python configure.py build`

## Running a Lua App

If the compilation is successful, you now have `bin/lt64.exe`, which is the main executable. This program launches a Lua script. The intention was for Limit Theory (and all mods) to be broken into many Lua scripts, which would then implement the gameplay, using script functions exposed by the underlying engine.

To launch a Lua script, you can again use the python helper:

- `python configure.py run`

To run the default script ('LTheory'), or

- `python configure.py run <script_name_without_extension>`

to run a specific script. All top-level scripts are in the `script/App` directory.

# Example of the Entire Process

An example of the entire sequence of commands to run LT, starting from nothing (but having the prerequisites installed):

Open Git Bash. Each line below is one command, some of which will take a while to complete:

```
cd ~/Desktop
git lfs install
git clone --recursive https://github.com/JoshParnell/ltheory.git ltheory
cd ltheory
python configure.py
python configure.py build
python configure.py run
```
