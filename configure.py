#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import shutil
import sys

ROOT = Path(__file__).resolve().parent
BUILD = ROOT / 'build'
CONFIG = os.environ.get('CMAKE_BUILD_TYPE', 'RelWithDebInfo')


def main():
    os.chdir(ROOT)
    command = sys.argv[1] if len(sys.argv) > 1 else 'configure'
    if command == 'configure':
        subprocess.run(['cmake', '-S', '.', '-B', str(BUILD),
                        '-DCMAKE_BUILD_TYPE=' + CONFIG] + sys.argv[2:], check=True)
    elif command == 'build':
        subprocess.run(['cmake', '--build', str(BUILD), '--config', CONFIG]
                       + sys.argv[2:], check=True)
    elif command == 'run':
        # CMake records the exact configuration-dependent target filename.
        executable = (BUILD / ('executable-' + CONFIG + '.txt')).read_text().strip()
        return subprocess.call([executable] + sys.argv[2:])
    elif command == 'clean':
        shutil.rmtree(ROOT / 'bin', ignore_errors=True)
        shutil.rmtree(BUILD, ignore_errors=True)
    else:
        raise ValueError('Usage: configure.py [configure|build|run|clean] [arguments...]')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (subprocess.CalledProcessError, OSError, ValueError) as error:
        print(error, file=sys.stderr)
        sys.exit(error.returncode if isinstance(error, subprocess.CalledProcessError) else 1)
