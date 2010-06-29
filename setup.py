#!/usr/bin/env python

from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

dystopia_ext = Extension("dystopia", ["dystopia.pyx"],
                         libraries=[ "tokyodystopia" ])

setup(cmdclass = { 'build_ext': build_ext },
      ext_modules = [ dystopia_ext ])


