"""Verify native output headers and archive build products, not a game release."""
import json
from pathlib import Path
import platform
import shutil
import struct
import subprocess
import sys
import tarfile


def git(*args):
    return subprocess.check_output(['git', *args], text=True).strip()


def verify_architecture(path, target):
    data = path.read_bytes()
    if target == 'windows-x64':
        assert data[:2] == b'MZ', f'Not a PE file: {path}'
        offset = struct.unpack_from('<I', data, 0x3c)[0]
        assert data[offset:offset + 4] == b'PE\0\0', path
        assert struct.unpack_from('<H', data, offset + 4)[0] == 0x8664, path
    elif target == 'linux-x64':
        assert data[:6] == b'\x7fELF\x02\x01', f'Not little-endian ELF64: {path}'
        assert struct.unpack_from('<H', data, 18)[0] == 62, path
    else:
        assert data[:4] == b'\xcf\xfa\xed\xfe', f'Not Mach-O 64: {path}'
        assert struct.unpack_from('<I', data, 4)[0] == 0x0100000c, path


def main():
    target = sys.argv[1]
    suffixes = {
        'windows-x64': ('.exe', '.dll'),
        'linux-x64': ('', '.so'),
        'macos-arm64': ('', '.dylib'),
    }
    executable_suffix, library_suffix = suffixes[target]
    executable = Path('bin/lt64' + executable_suffix)
    library = Path('bin/libphx64' + library_suffix)
    for path in (executable, library):
        verify_architecture(path, target)
    cache = Path('build/CMakeCache.txt').read_text()
    assert 'PHX_AUDIO_BACKEND:STRING=MINIAUDIO' in cache
    engine_sha = git('-C', 'libphx', 'rev-parse', 'HEAD')
    assert engine_sha == git('rev-parse', 'HEAD:libphx'), 'Engine differs from gitlink'

    name = 'ltheory-' + target + '-miniaudio'
    output = Path('build/ci-dist')
    staging = output / name
    staging.mkdir(parents=True, exist_ok=True)
    files = [executable, library]
    if target == 'windows-x64':
        files += list(Path('bin').glob('*.dll'))
        files += list(Path('bin').glob('*.pdb'))
        required = ['glew32.dll', 'liblz4.dll', 'lua51.dll', 'SDL2.dll']
        for filename in required:
            assert (Path('bin') / filename).is_file(), filename
    for path in set(files):
        shutil.copy2(path, staging / path.name)
    for symbols in Path('bin').glob('*.dSYM'):
        shutil.copytree(symbols, staging / symbols.name, dirs_exist_ok=True)
    compiler_config = next(Path('build/CMakeFiles').glob('*/CMakeCXXCompiler.cmake'))
    shutil.copy2(compiler_config, staging / 'CMakeCXXCompiler.cmake')

    metadata = {
        'game_sha': git('rev-parse', 'HEAD'),
        'engine_sha': engine_sha,
        'platform': target,
        'runner_os': platform.platform(),
        'configuration': 'RelWithDebInfo',
        'audio': 'MINIAUDIO',
        'cmake': subprocess.check_output(['cmake', '--version'], text=True).strip(),
    }
    (staging / 'build-info.json').write_text(json.dumps(metadata, indent=2) + '\n')
    (staging / 'README.txt').write_text(
        'Compilation artifacts only; not a standalone game distribution.\n'
        'Use with the game and pinned engine source commits in build-info.json.\n'
        'Place binaries in the matching game checkout bin/ directory.\n'
        'Game scripts, engine FFI scripts and Git LFS assets are required.\n'
        'Launch from the game root: bin/lt64 LTheory (Windows: bin/lt64.exe LTheory).\n'
        'Linux/macOS require the platform dependencies documented in README.md.\n'
        'macOS binaries refer to Homebrew libraries; they are not relocatable.\n'
        'Windows requires the Microsoft Visual C++ runtime.\n'
        'No gameplay or audio runtime test was performed by CI.\n'
    )
    with tarfile.open(output / (name + '.tar.gz'), 'w:gz') as archive:
        archive.add(staging, arcname=name)
    print(json.dumps(metadata, indent=2))


if __name__ == '__main__':
    main()
