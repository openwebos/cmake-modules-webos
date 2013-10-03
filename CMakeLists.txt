# @@@LICENSE
#
#      Copyright (c) 2012-2013 LG Electronics, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# LICENSE@@@

#
# cmake-modules-webos/CMakeLists.txt
#

# Commented-out lines are used for testing

cmake_minimum_required(VERSION 2.8.7)

project(cmake-modules-webos NONE)

# Make sure we use ourself to build ourself
include(${CMAKE_SOURCE_DIR}/webOS/webOS.cmake)

set(VERSION_ARGS 1 0 0 QUALIFIER RC6)
webos_modules_init(${VERSION_ARGS})
webos_component(${VERSION_ARGS})

# Install the modules directly into the /Modules directory of the currently running cmake instance.
# This avoids users having to add a path to CMAKE_MODULES_PATH before they can include webOS/webOS
install(DIRECTORY webOS DESTINATION ${CMAKE_ROOT}/Modules FILES_MATCHING PATTERN "*" PATTERN ".*" EXCLUDE)
install(FILES REFERENCE.md DESTINATION ${CMAKE_ROOT}/Modules/webOS)

#
# Tests - uncomment the appropriate lines to test the modules.
#

#project(hello C)
#webos_upstream_from_repo(0.4.12 2)

#webos_add_compiler_flags(RELEASE -O2 -O0)
#webos_add_linker_options(RELEASE --as-needed "-map foo.map")
#message(STATUS "CMAKE_C_FLAGS_RELEASE: ${CMAKE_C_FLAGS_RELEASE}")

#include_directories(include/public)
#file(WRITE include/public/hello/hello.h.in "#include <stdio.h>")
#webos_configure_header_files(include/public INSTALL)
#file(WRITE src/hello.c "#include \"hello/hello.h\"\nmain() { printf(\"Hello\\n\"); }")
#list(APPEND sourcelist src/hello.c)
#file(WRITE src/world.c.in "void project(void) { printf(\"@CMAKE_PROJECT_NAME@\\n\"); }")
#webos_configure_source_files(sourcelist src/world.c)
#add_executable(${CMAKE_PROJECT_NAME} ${sourcelist})
#webos_build_program() # NAME hello2 ROOTFS RESTRICTED_PERMISSIONS

#file(WRITE conf/hello.in "@CMAKE_PROJECT_NAME@")
#webos_build_daemon(NAME hello LAUNCH conf/hello ROOTFS RESTRICTED_PERMISSIONS)

#add_library(libhello SHARED src/hello.c)
#webos_build_library(TARGET libhello RESTRICTED_PERMISSIONS)

#webos_core_os_dep()
#webos_machine_dep()
#webos_machine_impl_dep()

#webos_install_symlink(cmake-${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION} ${WEBOS_INSTALL_DATADIR}/cmake)

#webos_include_install_paths()

