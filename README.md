cmake-modules-webos
===================

Summary
-------
CMake modules needed to build Open webOS components

Description
-----------
_cmake-modules-webos_ extends your CMake installation with a set of functions
and macros that are required to build the majority of those Open webOS
components which use CMake for configuration.


Dependencies
============

Below are the tools (and their minimum versions) required to build
_cmake-modules-webos_:

- cmake 2.8.7
- make (any version)

How to Build on Linux
=====================

## Building

Once you have downloaded the source, enter the following to build it (after
changing into the directory under which it was downloaded):

    $ mkdir BUILD
    $ cd BUILD
    $ cmake ..
    $ make
    $ sudo make install

The modules files will be installed in a `webOS` subdirectory of the `Modules`
directory of the instance of CMake used to configure the component.

To see a list of the make targets that `cmake` has generated, enter:

    $ make help

## Uninstalling

From the directory where you originally ran `make install`, enter:

    $ sudo make uninstall

## Documentation

_cmake-modules-webos_ works with the standard CMake documentation system. For 
more information on it, enter:

   $ cmake --help-module webOS/webOS

# Copyright and License Information

All content, including all source code files and documentation files in this repository are:

Copyright (c) 2012 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this content except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
