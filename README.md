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
python3 configure.py configure -DPHX_AUDIO=OFF -DCMAKE_OSX_ARCHITECTURES=arm64
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
