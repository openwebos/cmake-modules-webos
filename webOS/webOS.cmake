# - Common CMake code for all Open webOS components
#
# Any Open webOS component whose root CMakeLists.txt is written by us must
# include() this module. 
#
# Usage:
#  include(webOS/webOS)
#  webos_modules_init(1 0 0 QUALIFIER RC4)
#
# Detailed documentation for the latest version is available from:
# https://github.com/openwebos/cmake-modules-webos/blob/master/REFERENCE.md
#
# @@@VERSION
# 1.0.0 RC4
# VERSION@@@
#

#=============================================================================
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
#=============================================================================

#
# webOS/webOS.cmake
#

# Environment variables imported:
# PKG_CONFIG_PATH

# Global variables settable from the command line:
# WEBOS_COMPONENT_VERSION   - the full version string from the build system
# WEBOS_CONFIG_BUILD_DOCS   - if defined, the "docs" and "install-docs" targets are made dependencies of "all" and "install"
# WEBOS_INSTALL_ROOT        - the root of the install tree
# WEBOS_TARGET_CORE_OS      - name of core OS dependency
# WEBOS_TARGET_MACHINE      - name of machine dependency
# WEBOS_TARGET_MACHINE_IMPL - name of "machine implementation" dependency

# Global variables exported to the calling CMakeLists.txt:
# WEBOS_BINARY_CONFIGURED_DIR - tree under which files processed by configure_file() are placed (its layout mirrors that of
#                               CMAKE_SOURCE_DIR)
# WEBOS_BINARY_DOCUMENTATION_DIR - tree under which results of running Doxygen are placed
# WEBOS_COMPONENT_VERSION   - the full version string
# WEBOS_API_VERSION         - just <major>.<minor>.<patch> (no <qualifier>) or <upstream-version>
# WEBOS_API_VERSION_MAJOR   - just <major> or first version field extracted from <upstream-version>
# WEBOS_COMPONENT_VERSION   - the full version string
# WEBOS_INSTALL_*           - various locations in the install tree
# WEBOS_PROJECT_SUMMARY     - the one-line summary of the project set by webos_project_summary()
# WEBOS_TARGET_CORE_OS      - name of core OS dependency
# WEBOS_TARGET_MACHINE      - name of machine dependency
# WEBOS_TARGET_MACHINE_IMPL - name of "machine implementation" dependency
# ENV{PKG_CONFIG_PATH}      - the setting for PKG_CONFIG_PATH to be placed in the environment for commands invoked by "make"

# TODO: Using PARENT_SCOPE, see if any macros can be turned into functions

cmake_minimum_required(VERSION 2.8.7)

include(CMakeParseArguments)

# XXX Make const
set(WEBOS_BINARY_CONFIGURED_DIR ${CMAKE_BINARY_DIR}/Configured)
set(WEBOS_BINARY_DOCUMENTATION_DIR ${CMAKE_BINARY_DIR}/Documentation)

# Usage: webos_append_new_to_list(<list-variable-name> <item> ...)
#
# Appends all <item>-s in the parameter list which are not already present in <list-variable-name>.
function(webos_append_new_to_list listvar)
	if(ARGC LESS 2)
		message(FATAL_ERROR "webos_append_new_to_list(): At least one item parameter must be provided")
	endif()

	set(ourvar ${${listvar}})
	foreach(item ${ARGN})
		list(FIND ourvar "${item}" found)
		if(found STREQUAL -1)
			list(APPEND ourvar "${item}")
		endif()
	endforeach()
	set(${listvar} ${ourvar} PARENT_SCOPE)
endfunction()

macro(_webos_check_init_version auth_version auth_qualifier)
	if(EXISTS ${CMAKE_SOURCE_DIR}/webOS/webOS.cmake)
		file(STRINGS ${CMAKE_SOURCE_DIR}/webOS/webOS.cmake _webos_contents)
	else()
		file(STRINGS ${CMAKE_ROOT}/Modules/webOS/webOS.cmake _webos_contents)
	endif()
	list(FIND _webos_contents "# @@@VERSION" _indx)
	if(${_indx} EQUAL -1)
		message(FATAL_ERROR "INTERNAL ERROR: No \"# @@@VERSION\" marker found in webOS/webOS.cmake .")
	endif()
	math(EXPR _indx "${_indx} + 1")
	list(GET _webos_contents ${_indx} _temp)
	# The line after "# @@@VERSION" is expected to have the format: "# major.minor.patch [qualifier]".
	# Convert into a list
	string(REPLACE " " ";" _temp "${_temp}")
	# Make sure _temp always has at least 3 elements
	string(ASCII 255 _no_qualifier)
	list(APPEND _temp ${_no_qualifier})
	list(GET _temp 1 _version)
	list(GET _temp 2 _qualifier)
	string(TOLOWER ${_qualifier} _qualifier)
	if(${auth_qualifier} STREQUAL ${_no_qualifier})
		set(_auth_qualifier "")
	else()
		set(_auth_qualifier ~${auth_qualifier})
	endif()

	if(${_qualifier} STREQUAL ${_no_qualifier})
		set(_show_qualifier "")
	else()
		set(_show_qualifier ~${_qualifier})
	endif()
	if(${auth_version} VERSION_LESS ${_version})
		# OK
	elseif((${auth_version} VERSION_EQUAL ${_version}) AND NOT (${auth_qualifier} STRGREATER ${_qualifier}))
		# OK
	else()
		message(FATAL_ERROR
		        "webos_modules_init():"
		        " Requested version (${auth_version}${_auth_qualifier}) is later than that being used"
		        " (${_version}${_show_qualifier}).")
	endif()
	message(STATUS "cmake-modules-webos: authored for version ${auth_version}${_auth_qualifier}; using version ${_version}${_show_qualifier}.")
	unset(_webos_contents)
	unset(_indx)
	unset(_temp)
	unset(_no_qualifier)
	unset(_version)
	unset(_qualifier)
	unset(_show_qualifier)
	unset(_auth_qualifier)
endmacro()


# Usage: webos_modules_init(<major-version> <minor-version> <patch-version> [QUALIFIER <qualifer>])
#
# Specifies the version of cmake-modules-webos for which the caller was authored (or most recently modified).
#
# Unfortunately, CMake doesn't like having cmake_minimum_required() in a macro, so we can't make that part of the contract :-( .
# Must be a macro as it can set the global variables
macro(webos_modules_init major minor patch)
	if(${CMAKE_BINARY_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
		message(FATAL_ERROR "Builds must be done \"out-of-source\".")
	endif()

	if(DEFINED _WEBOS_MODULES_CONTRACT_VERSION)
		message(FATAL_ERROR "webos_modules_init(): Previously invoked")
	endif()

	cmake_parse_arguments(webos_modules_init "" "QUALIFIER" "" ${ARGN})
	if(DEFINED webos_modules_init_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "webos_modules_init(): Unrecognized arguments: '${webos_modules_init_UNPARSED_ARGUMENTS}'")
	endif()

	set(_WEBOS_MODULES_CONTRACT_VERSION ${major}.${minor}.${patch})
	# Version fields must be digits only (can't use VERSION_GREATER 0.0.0, as it succeeds if a field is negative)
	if(NOT ${_WEBOS_MODULES_CONTRACT_VERSION} MATCHES "^[0-9.]+$")
		message(FATAL_ERROR
		        "webos_modules_init():"
		        " Version fields must be non-negative integers: '${_WEBOS_MODULES_CONTRACT_VERSION}'")
	endif()
	if(DEFINED webos_modules_init_QUALIFIER)
		if(NOT ${webos_modules_init_QUALIFIER} MATCHES "^[A-Za-z0-9]+$")
			message(FATAL_ERROR "webos_modules_init(): Invalid QUALIFIER value: '${webos_modules_init_QUALIFIER}'")
		endif()
		string(TOLOWER ${webos_modules_init_QUALIFIER} _WEBOS_MODULES_CONTRACT_VERSION_QUALIFIER)
	else()
		# Make sure this is STRGREATER than any possible valid qualifier to simplify comparing
		string(ASCII 255 _WEBOS_MODULES_CONTRACT_VERSION_QUALIFIER)
	endif()
	_webos_check_init_version(${_WEBOS_MODULES_CONTRACT_VERSION} ${_WEBOS_MODULES_CONTRACT_VERSION_QUALIFIER})

	# XXX Why does CMAKE_BUILD_TYPE default to empty?
	if("${CMAKE_BUILD_TYPE}" STREQUAL "")
		set(CMAKE_BUILD_TYPE Release)
	endif()

	if(DEFINED WEBOS_INSTALL_ROOT)
		if(NOT IS_ABSOLUTE ${WEBOS_INSTALL_ROOT})
			# XXX make canonical
			set(WEBOS_INSTALL_ROOT ${CMAKE_BINARY_DIR}/${WEBOS_INSTALL_ROOT})
		endif()
		# Remove any trailing /-s (this correct even when ${WEBOS_INSTALL_ROOT} is "/").
		string(REGEX REPLACE "/+$" "" WEBOS_INSTALL_ROOT ${WEBOS_INSTALL_ROOT})
	else()
		set(WEBOS_INSTALL_ROOT /usr/local/webos)
	endif()

	_webos_init_install_vars()
	# XXX Consider unset-ing CMAKE_INSTALL_PREFIX to make sure no one uses it
	set(CMAKE_INSTALL_PREFIX ${WEBOS_INSTALL_ROOT})

	# Set WEBOS_PROJECT_SUMMARY from the Summary subsection of README.md
	if(EXISTS ${CMAKE_SOURCE_DIR}/README.md)
		file(STRINGS ${CMAKE_SOURCE_DIR}/README.md _readme_contents)
		list(FIND _readme_contents Summary _indx)
		if(${_indx} EQUAL -1)
			message(FATAL_ERROR "No \"Summary\" subsection found in README.md .")
		endif()
		math(EXPR _indx "${_indx} + 2")
		list(GET _readme_contents ${_indx} WEBOS_PROJECT_SUMMARY)
		math(EXPR _indx "${_indx} + 1")
		list(GET _readme_contents ${_indx} _temp)
		if(NOT "${_temp}" STREQUAL "")
			message(FATAL_ERROR "The \"Summary\" subsection in README.md must be a single line.")
		endif()
		unset(_readme_contents)
		unset(_indx)
		unset(_temp)
	else()
		message(WARNING "No README.md found.")
		set(WEBOS_PROJECT_SUMMARY "(unknown)")
	endif()

	# When being run under OE, assume it has set PKG_CONFIG_PATH correctly and don't touch it here. CMAKE_FIND_ROOT_PATH is
	# only meant to be set when cross-compiling, so its absence is an appropriate way to detect when we should append to
	# PKG_CONFIG_PATH.
	if(NOT DEFINED CMAKE_FIND_ROOT_PATH)
		# Set up PKG_CONFIG_PATH to look first in the (potentially) overridden installation location and then in both of
		# our default installation locations before searching in the standard locations. (That pkg-config does this has
		# been confirmed in spite of its man page implying that it does something else.) usr/lib/pkgconfig must be searched
		# as well as usr/share/pkgconfig as not all FOSS components have been updated for the new convention; pkg-config's
		# practice of searching usr/lib/pkgconfig before usr/share/pkgconfig is followed, even though it seems wrong. Note
		# that duplication in the parameter list of webos_append_new_to_list() is safe (so it doesn't matter if
		# WEBOS_INSTALL_ROOT is set to either /usr/local/webos or /opt/webos).
		set(_pkgconfigpath $ENV{PKG_CONFIG_PATH})
		string(REGEX REPLACE ":" ";" _pkgconfigpath "${_pkgconfigpath}")
		webos_append_new_to_list(_pkgconfigpath ${WEBOS_INSTALL_LIBDIR}/pkgconfig
		                                        ${WEBOS_INSTALL_PKGCONFIGDIR}
		                                        /usr/local/webos/usr/lib/pkgconfig
		                                        /usr/local/webos/usr/share/pkgconfig
		                                        /opt/webos/usr/lib/pkgconfig
		                                        /opt/webos/usr/share/pkgconfig)
		string(REGEX REPLACE ";" ":" _pkgconfigpath "${_pkgconfigpath}")
		set(ENV{PKG_CONFIG_PATH} "${_pkgconfigpath}")
		unset(_pkgconfigpath)
	endif()

	message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
	message(STATUS "ENV{PKG_CONFIG_PATH}: $ENV{PKG_CONFIG_PATH}")
	message(STATUS "WEBOS_PROJECT_SUMMARY: ${WEBOS_PROJECT_SUMMARY}")
	if("${WEBOS_INSTALL_ROOT}" STREQUAL "")
		message(STATUS "WEBOS_INSTALL_ROOT: (empty => /)")
	else()
		message(STATUS "WEBOS_INSTALL_ROOT: ${WEBOS_INSTALL_ROOT}")
	endif()
endmacro()


macro(_webos_set_from_env var env_var default)
	if(DEFINED ENV{${env_var}})
		set(${var} "$ENV{${env_var}}")
		if(NOT IS_ABSOLUTE "${${var}}" AND NOT "${${var}}" STREQUAL "")
			message(FATAL_ERROR "ENV{${env_var}} is not an absolute path: '${${var}}'")
		endif()
	else()
		set(${var} "${default}")
	endif()
#	message(STATUS "${var} = ${${var}}")
#	message(STATUS "| {{${${var}}}} | {{${var}}} |")
endmacro()


# The environment setting take precedence
# TODO: Resolve FHS requiring if base_prefix is /opt/webos, then there must be a link from /etc${base_prefix} to ${sysconfdir}
#       /srv${base_prefix} to ${servicedir}, and /var${base_prefix} to ${localstatedir}
# TODO: Multi-arch support: just set LIB_SUFFIX to be /<multi-arch-tuple> ? (XXX LIB_SUFFIX is not a standard CMAKE variable, but
# appears to be commonly used.)
macro(_webos_init_install_vars)
	# Path prefixes
	_webos_set_from_env(WEBOS_INSTALL_ROOT               base_prefix             "${WEBOS_INSTALL_ROOT}")  # WEBOS_INSTALL_ROOT can be empty
	_webos_set_from_env(WEBOS_INSTALL_PREFIX             prefix                   ${WEBOS_INSTALL_ROOT}/usr)
	_webos_set_from_env(WEBOS_INSTALL_EXEC_PREFIX        exec_prefix              ${WEBOS_INSTALL_PREFIX})

	# Base paths (on root filesystem)
	_webos_set_from_env(WEBOS_INSTALL_BASE_BINDIR        base_bindir              ${WEBOS_INSTALL_ROOT}/bin)
	_webos_set_from_env(WEBOS_INSTALL_BASE_SBINDIR       base_sbindir             ${WEBOS_INSTALL_ROOT}/sbin)
	_webos_set_from_env(WEBOS_INSTALL_BASE_LIBDIR        base_libdir              ${WEBOS_INSTALL_ROOT}/lib${LIB_SUFFIX})

	# Architecture independent paths
	_webos_set_from_env(WEBOS_INSTALL_DATADIR            datadir                  ${WEBOS_INSTALL_PREFIX}/share)
	_webos_set_from_env(WEBOS_INSTALL_SYSCONFDIR         sysconfdir               ${WEBOS_INSTALL_ROOT}/etc)
	_webos_set_from_env(WEBOS_INSTALL_SERVICEDIR         servicedir               ${WEBOS_INSTALL_ROOT}/srv)
	# FHS: sharedstatedir isn't used
	_webos_set_from_env(WEBOS_INSTALL_LOCALSTATEDIR      localstatedir            ${WEBOS_INSTALL_ROOT}/var)
	_webos_set_from_env(WEBOS_INSTALL_INFODIR            infodir                  ${WEBOS_INSTALL_DATADIR}/info)
	_webos_set_from_env(WEBOS_INSTALL_MANDIR             mandir                   ${WEBOS_INSTALL_DATADIR}/man)
	_webos_set_from_env(WEBOS_INSTALL_DOCDIR             docdir                   ${WEBOS_INSTALL_DATADIR}/doc)

	# Architecture dependent paths
	_webos_set_from_env(WEBOS_INSTALL_BINDIR             bindir                   ${WEBOS_INSTALL_EXEC_PREFIX}/bin)
	_webos_set_from_env(WEBOS_INSTALL_SBINDIR            sbindir                  ${WEBOS_INSTALL_EXEC_PREFIX}/sbin)
	_webos_set_from_env(WEBOS_INSTALL_LIBEXEC            libexecdir               ${WEBOS_INSTALL_EXEC_PREFIX}/libexec)
	_webos_set_from_env(WEBOS_INSTALL_LIBDIR             libdir                   ${WEBOS_INSTALL_EXEC_PREFIX}/lib${LIB_SUFFIX})
	_webos_set_from_env(WEBOS_INSTALL_INCLUDEDIR         includedir               ${WEBOS_INSTALL_EXEC_PREFIX}/include)
	# Leave this one out until we come across a need for it.
	# _webos_set_from_env(WEBOS_INSTALL_OLDINCLUDEDIR    oldincludedir            ${WEBOS_INSTALL_EXEC_PREFIX}/include)

	# Variables invented by us for other standard locations
	_webos_set_from_env(WEBOS_INSTALL_BOOTDIR            webos_bootdir            ${WEBOS_INSTALL_ROOT}/boot)
	_webos_set_from_env(WEBOS_INSTALL_DEFAULTCONFDIR     webos_defaultconfdir     ${WEBOS_INSTALL_SYSCONFDIR}/default)
	_webos_set_from_env(WEBOS_INSTALL_EXECSTATEDIR       webos_execstatedir       ${WEBOS_INSTALL_LOCALSTATEDIR}/lib)
	_webos_set_from_env(WEBOS_INSTALL_HOMEDIR            webos_homedir            ${WEBOS_INSTALL_ROOT}/home)
	_webos_set_from_env(WEBOS_INSTALL_MEDIADIR           webos_mediadir           ${WEBOS_INSTALL_ROOT}/media)
	_webos_set_from_env(WEBOS_INSTALL_MNTDIR             webos_mntdir             ${WEBOS_INSTALL_ROOT}/mnt)
	_webos_set_from_env(WEBOS_INSTALL_LOGDIR             webos_logdir             ${WEBOS_INSTALL_LOCALSTATEDIR}/log)
	# Use the correct tree for architecture independent files (which is supported by modern versions of pkg-config)
	_webos_set_from_env(WEBOS_INSTALL_PKGCONFIGDIR       webos_pkgconfigdir       ${WEBOS_INSTALL_DATADIR}/pkgconfig)
	_webos_set_from_env(WEBOS_INSTALL_PRESERVEDTMPDIR    webos_preservedtmpdir    ${WEBOS_INSTALL_LOCALSTATEDIR}/tmp)
	_webos_set_from_env(WEBOS_INSTALL_RUNTIMEINFODIR     webos_runtimeinfodir     ${WEBOS_INSTALL_LOCALSTATEDIR}/run)
	# This one will eventually default to ${WEBOS_INSTALL_SYSCONFDIR}/init
	_webos_set_from_env(WEBOS_INSTALL_UPSTARTCONFDIR     webos_upstartconfdir     ${WEBOS_INSTALL_SYSCONFDIR}/event.d)

	# Variables for webOS additions to the FS hierarchy
	_webos_set_from_env(WEBOS_INSTALL_CRYPTOFSDIR        webos_cryptofsdir        ${WEBOS_INSTALL_MEDIADIR}/cryptofs)
	_webos_set_from_env(WEBOS_INSTALL_BROWSERSTORAGEDIR  webos_browserstoragedir  ${WEBOS_INSTALL_CRYPTOFSDIR}/.browser)
	_webos_set_from_env(WEBOS_INSTALL_APPSTORAGEDIR      webos_appstoragedir      ${WEBOS_INSTALL_CRYPTOFSDIR}/apps)
	_webos_set_from_env(WEBOS_INSTALL_INSTALLEDAPPSDIR   webos_installedappsdir   ${WEBOS_INSTALL_APPSTORAGEDIR}/usr/palm/applications)
	_webos_set_from_env(WEBOS_INSTALL_LOCALSTORAGEDIR    webos_localstoragedir    ${WEBOS_INSTALL_MEDIADIR}/internal)
	_webos_set_from_env(WEBOS_INSTALL_FILECACHEDIR       webos_filecachedir       ${WEBOS_INSTALL_LOCALSTATEDIR}/file-cache)
	_webos_set_from_env(WEBOS_INSTALL_SYSBUS_PUBSERVICESDIR     webos_sysbus_pubservicesdir     ${WEBOS_INSTALL_DATADIR}/dbus-1/services)
	_webos_set_from_env(WEBOS_INSTALL_SYSBUS_PRVSERVICESDIR     webos_sysbus_prvservicesdir     ${WEBOS_INSTALL_DATADIR}/dbus-1/system-services)
	_webos_set_from_env(WEBOS_INSTALL_SYSBUS_PUBROLESDIR        webos_sysbus_pubrolesdir        ${WEBOS_INSTALL_DATADIR}/ls2/roles/pub)
	_webos_set_from_env(WEBOS_INSTALL_SYSBUS_PRVROLESDIR        webos_sysbus_prvrolesdir        ${WEBOS_INSTALL_DATADIR}/ls2/roles/prv)
	_webos_set_from_env(WEBOS_INSTALL_SYSBUS_DYNPUBSERVICESDIR  webos_sysbus_dynpubservicesdir  ${WEBOS_INSTALL_LOCALSTATEDIR}/palm/ls2/services/pub)
	_webos_set_from_env(WEBOS_INSTALL_SYSBUS_DYNPRVSERVICESDIR  webos_sysbus_dynprvservicesdir  ${WEBOS_INSTALL_LOCALSTATEDIR}/palm/ls2/services/prv)
	_webos_set_from_env(WEBOS_INSTALL_SYSBUS_DYNPUBROLESDIR     webos_sysbus_dynpubrolesdir     ${WEBOS_INSTALL_LOCALSTATEDIR}/palm/ls2/roles/pub)
	_webos_set_from_env(WEBOS_INSTALL_SYSBUS_DYNPRVROLESDIR     webos_sysbus_dynprvrolesdir     ${WEBOS_INSTALL_LOCALSTATEDIR}/palm/ls2/roles/prv)
	# Eventually, these will be moved to somewhere else:
	_webos_set_from_env(WEBOS_INSTALL_WEBOS_PREFIX              webos_prefix                    ${WEBOS_INSTALL_PREFIX}/palm)
	_webos_set_from_env(WEBOS_INSTALL_WEBOS_ACCTTEMPLATESDIR    webos_accttemplatesdir          ${WEBOS_INSTALL_PREFIX}/palm/public/accounts)
	_webos_set_from_env(WEBOS_INSTALL_WEBOS_APPLICATIONSDIR     webos_applicationsdir           ${WEBOS_INSTALL_PREFIX}/palm/applications)
	_webos_set_from_env(WEBOS_INSTALL_WEBOS_FRAMEWORKSDIR       webos_frameworksdir             ${WEBOS_INSTALL_PREFIX}/palm/frameworks)
	_webos_set_from_env(WEBOS_INSTALL_WEBOS_KEYSDIR             webos_keysdir                   ${WEBOS_INSTALL_PREFIX}/palm/data)
	_webos_set_from_env(WEBOS_INSTALL_WEBOS_SERVICESDIR         webos_servicesdir               ${WEBOS_INSTALL_PREFIX}/palm/services)
	_webos_set_from_env(WEBOS_INSTALL_WEBOS_SOUNDSDIR           webos_soundsdir                 ${WEBOS_INSTALL_PREFIX}/palm/sounds)
	_webos_set_from_env(WEBOS_INSTALL_WEBOS_SYSCONFDIR          webos_sysconfdir                ${WEBOS_INSTALL_SYSCONFDIR}/palm)
	_webos_set_from_env(WEBOS_INSTALL_WEBOS_LOCALSTATEDIR       webos_localstatedir             ${WEBOS_INSTALL_LOCALSTATEDIR}/palm)
	_webos_set_from_env(WEBOS_INSTALL_SYSMGR_DATADIR            webos_sysmgr_datadir            ${WEBOS_INSTALL_LIBDIR}/luna)
	_webos_set_from_env(WEBOS_INSTALL_SYSMGR_LOCALSTATEDIR      webos_sysmgr_localstatedir      ${WEBOS_INSTALL_LOCALSTATEDIR}/luna)
endmacro()


# Things common to webos_component() and webos_upstream_from_repo()
function(_webos_do_common caller)
	# We follow the Debian convention for component names: http://www.debian.org/doc/debian-policy/ch-controlfields.html#s-f-Source,
	# but relax it for project names to allow capital letters.
	if(NOT ${CMAKE_PROJECT_NAME} MATCHES "^[A-Za-z][A-Za-z0-9.+-]+$")
		message(FATAL_ERROR "Invalid project name: '${CMAKE_PROJECT_NAME}'. Project names must be at least two characters"
		                    " long and can only be formed from letters, digits, and these punctuation characters: . + -")
	endif()

	if(DEFINED WEBOS_API_VERSION)
		message(FATAL_ERROR "Can only ${caller}() once")
	endif()

	if(UNIX)
		# Generate an "uninstall" make target. NB. install_manifest.txt contains absolute paths and does not contain any
		# directories. Use the convenient fact that CMake lists expand with embedded semicolons between items to write separate
		# shell commands in separate lines. Note that the destination for everything that's installed will be prefixed with the
		# value of the DESTDIR environment variable at the time "make install" is run, so what the uninstall target removes needs
		# to be prefixed by it as well. The user will need to make sure that it's set to the same value it had when "make install"
		# was run.
		set(shell_cmd "if [ -r ${CMAKE_BINARY_DIR}/install_manifest.txt ]"
		              "then xargs -I @ -t rm -f $DESTDIR@ < ${CMAKE_BINARY_DIR}/install_manifest.txt 2>&1"
		              "else echo Unable to uninstall: ${CMAKE_BINARY_DIR}/install_manifest.txt not found"
		              "fi")
		add_custom_target(uninstall
		                  COMMAND sh -c "${shell_cmd}"
		                  VERBATIM
		                  COMMENT "Uninstalling from ${WEBOS_INSTALL_ROOT}")
	else()
		message(FATAL_ERROR "INTERNAL ERROR: _webos_do_common() needs work for non-UNIX builds.")
	endif()
endfunction()


# Must be a macro as it can set the global variable WEBOS_COMPONENT_VERSION
macro(_webos_set_component_version version_string)
	if(DEFINED WEBOS_COMPONENT_VERSION)
		# Enclose in quotes to handle case of botched -D setting from the command line
		if(NOT ("${WEBOS_COMPONENT_VERSION}" STREQUAL ${version_string}))
			message(FATAL_ERROR "Component version from build system (${WEBOS_COMPONENT_VERSION}) != configured"
			                    " version (${version_string})")
		endif()
	else()
		set(WEBOS_COMPONENT_VERSION ${version_string} CACHE FORCE "The version of the component")
	endif()
endmacro()


function(_webos_messages_versions)
	message(STATUS "WEBOS_COMPONENT_VERSION: ${WEBOS_COMPONENT_VERSION}")
	message(STATUS "WEBOS_API_VERSION: ${WEBOS_API_VERSION}")
	message(STATUS "WEBOS_API_VERSION_MAJOR: ${WEBOS_API_VERSION_MAJOR}")
endfunction()


# Usage: webos_component(<major-version> <minor-version> <patch-version> [QUALIFIER <qualifer>])
#
# <qualifier> is something like "RC1". If present, it is converted to lowercase and appended to 
# <major-version>.<minor-version>.<patch-version> separated by a "~" when forming
# WEBOS_COMPONENT_VERSION.
#
# Must be a macro as it sets global variables.
# Unfortunately, CMake doesn't like having project() in a macro, so we can't specify it here :-( .
macro(webos_component major minor patch)
	cmake_parse_arguments(webos_component "" "QUALIFIER" "" ${ARGN})
	if(DEFINED webos_component_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "webos_component(): Unrecognized arguments: '${webos_component_UNPARSED_ARGUMENTS}'")
	endif()
	_webos_do_common(webos_component)

	set(WEBOS_API_VERSION ${major}.${minor}.${patch})

	# Version fields must be digits only (can't use VERSION_GREATER 0.0.0, as it succeeds if a field is negative)
	if(NOT ${WEBOS_API_VERSION} MATCHES "^[0-9.]+$")
		message(FATAL_ERROR "webos_component(): Version fields must be non-negative integers: '${WEBOS_API_VERSION}'")
	endif()
	set(WEBOS_API_VERSION_MAJOR ${major})

	if(DEFINED webos_component_QUALIFIER)
		if(NOT ${webos_component_QUALIFIER} MATCHES "^[A-Za-z0-9]+$")
			message(FATAL_ERROR "webos_component(): Invalid QUALIFIER value: '${webos_component_QUALIFIER}'")
		endif()
		string(TOLOWER ~${webos_component_QUALIFIER} webos_component_QUALIFIER)
	endif()
	_webos_set_component_version(${WEBOS_API_VERSION}${webos_component_QUALIFIER})

	_webos_messages_versions()
endmacro()


# Usage: webos_upstream_from_repo(<upstream-version> <change-count>)
#
# <change-count> is the number of features/bug-fixes we've added to version <upstream-version> of the component. If <change-count>
# is 0, then don't append the "-0webos<change-count>" suffix to <upstream-version> when creating WEBOS_COMPONENT_VERSION.
#
# Must be a macro as it sets global variables.
# Unfortunately, CMake doesn't like having project() in a macro, so we can't specify it here :-( .
macro(webos_upstream_from_repo upstream_version change_count)
	_webos_do_common(webos_upstream_from_repo)

	set(WEBOS_API_VERSION ${upstream_version})
	# <change-count> must be a non-negative integer
	if(NOT ${change_count} MATCHES "^[0-9]+$")
		message(FATAL_ERROR "webos_upstream_from_repo(): <change-count> is not a non-negative integer: '${change_count}'")
	endif()
	# First period-separated field (which must a non-negative integer) is the major version
	string(REGEX REPLACE "^([0-9]+).*$" "\\1" WEBOS_API_VERSION_MAJOR ${upstream_version})
	if(${WEBOS_API_VERSION_MAJOR} STREQUAL ${upstream_version})
		message(FATAL_ERROR
		        "webos_upstream_from_repo():"
		        " <upstream-version> does not begin with a non-negative integer: '${WEBOS_API_VERSION}'")
	endif()

	if(${change_count} EQUAL 0)
		_webos_set_component_version(${upstream_version})
	else()
		_webos_set_component_version(${upstream_version}-0webos${change_count})
	endif()

	_webos_messages_versions()
endmacro()

macro(_webos_set_bin_inst_dir outvar admin rootfs)
	# instdir_<ADMIN>_<ROOTFS>
	set(instdir_FALSE_FALSE ${WEBOS_INSTALL_BINDIR})
	set(instdir_TRUE_FALSE ${WEBOS_INSTALL_SBINDIR})
	set(instdir_FALSE_TRUE ${WEBOS_INSTALL_BASE_BINDIR})
	set(instdir_TRUE_TRUE ${WEBOS_INSTALL_BASE_SBINDIR})
	set(${outvar} ${instdir_${admin}_${rootfs}})
endmacro()


macro(_webos_set_bin_permissions outvar restricted)
	set(${outvar} PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
	if(NOT ${restricted})
		list(APPEND ${outvar} GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
	endif()
endmacro()


# Usage: _webos_make_path_absolute(<absolute-prefix> <name-of-variable> <default-value> <strip>)
#
# Makes the path in <name-of-variable> absolute by prepending <absolute-prefix> if it's relative. If <name-of-variable> is
# undefined or empty, <default-value> (which can be relative) is used for its value. Set <strip> to TRUE to strip any trailing
# slashes in the resulting path.
macro(_webos_make_path_absolute absprefix invar default notrailingslash)
	# First deal with default values
	if(NOT DEFINED ${invar} OR ${invar} STREQUAL "" )
		if(default STREQUAL "")
			message(FATAL_ERROR "_webos_make_path_absolute(): Need to use <default-value>, but it's empty")
		endif()
		set(_temp ${default})
	else()
		set(_temp ${${invar}})
	endif()

	# get_filename_component will strip any trailing slashes, so capture whether the initial path had one
	# so we can add it back if notrailingslassh is false.
	if("${_temp}" MATCHES "/+$")
		set(_hadslash TRUE)
	else()
		set(_hadslash FALSE)
	endif()

	# If we need the provided prefix, check that it is provided and absolute, then prepend it
	if(NOT IS_ABSOLUTE ${_temp})
		if("${absprefix}" STREQUAL "")
			message(FATAL_ERROR "_webos_make_path_absolute(): Need to use <absolute-prefix>, but it's empty")
		endif()

		if(NOT IS_ABSOLUTE ${absprefix})
			message(FATAL_ERROR
			        "_webos_make_path_absolute():" 
			        " Need to use <absolute-prefix>, but it's a relative path: '${absprefix}')")
		endif()

		set(_temp ${absprefix}/${_temp})
	endif()

	# Use get_filename_component regardless as it cleans up the path, removing "." and ".."
	get_filename_component(${invar} ${_temp} ABSOLUTE)

	# Append a trailing slash if the original had one, and notrailingslash is false
	# NB: need to expand notrailingslash, otherwise the NOT just checks for existence of the variable
	if(_hadslash AND NOT ${notrailingslash})
		set(${invar} ${${invar}}/)
	endif()

	unset(_temp)
	unset(_hadslash)
endmacro()


# Usage: webos_make_source_path_absolute(<name-of-variable> <default-value> <strip>)
#
# Makes the path in <name-of-variable> absolute by prepending CMAKE_SOURCE_DIR if it's relative. If <name-of-variable> is undefined
# or empty, <default-value> (which can be relative) is used for its value. Set <strip> to TRUE to strip any trailing slashes in the
# resulting path.
macro(webos_make_source_path_absolute invar default notrailingslash)
	_webos_make_path_absolute(${CMAKE_SOURCE_DIR} "${invar}" "${default}" "${notrailingslash}")
endmacro()


# Usage: webos_make_binary_path_absolute(<name-of-variable> <default-value> <strip>)
#
# Makes the path in <name-of-variable> absolute by prepending CMAKE_BINARY_DIR if it's relative. If <name-of-variable> is undefined
# or empty, <default-value> (which can be relative) is used for its value. Set <strip> to TRUE to strip any trailing slashes in the
# resulting path.
macro(webos_make_binary_path_absolute invar default notrailingslash)
	_webos_make_path_absolute(${CMAKE_BINARY_DIR} "${invar}" "${default}" "${notrailingslash}")
endmacro()


# Usage: webos_build_program([NAME <name>] [ADMIN] [ROOTFS] [RESTRICTED_PERMISSIONS])
#
# <name> defaults to CMAKE_PROJECT_NAME
function(webos_build_program)
	cmake_parse_arguments(webos_program "ROOTFS;ADMIN;RESTRICTED_PERMISSIONS" "NAME" "" ${ARGN})
	if(DEFINED webos_program_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "webos_build_program(): Unrecognized arguments: '${webos_program_UNPARSED_ARGUMENTS}'")
	endif()

	if(NOT DEFINED webos_program_NAME)
		set(webos_program_NAME ${CMAKE_PROJECT_NAME})
	endif()
	_webos_set_bin_inst_dir(destdir ${webos_program_ADMIN} ${webos_program_ROOTFS})
	_webos_set_bin_permissions(permissions ${webos_program_RESTRICTED_PERMISSIONS})

	# powerd had this -- is it necessary?
	# set_property(TARGET ${webos_program_NAME} PROPERTY INSTALL_RPATH_USE_LINK_PATH TRUE)

	install(TARGETS ${webos_program_NAME} DESTINATION ${destdir} ${permissions})
endfunction()


# Usage: webos_build_daemon([NAME <name>] [LAUNCH <path-to-basename-or-dirname>] [ROOTFS] [RESTRICTED_PERMISSIONS])
#
# <name> defaults to CMAKE_PROJECT_NAME. If <path-to-basename-or-dirname> is a directory, then all of the *.in files in the tree
# under it are configured and installed (without the .in suffix) under Upstart conf directory. Otherwise, the file
# <path-to-basename>.in is configured and the resulting <path-to-basename> installed in the Upstart conf directory.
# <path-to-basename-or-dirname> defaults to files/launch/<name>.
#
# Only files with a .in suffix will be installed.
# Files with the dual .conf.in suffix, intended for use with Upstart 1.8 or later, will be installed under SYSCONFDIR/init
#
function(webos_build_daemon)
    cmake_parse_arguments(webos_daemon "ROOTFS;RESTRICTED_PERMISSIONS" "NAME;LAUNCH" "" ${ARGN})
    if(DEFINED webos_daemon_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "webos_build_daemon(): Unrecognized arguments: '${webos_daemon_UNPARSED_ARGUMENTS}'")
    endif()

    if(NOT DEFINED webos_daemon_NAME)
        set(webos_daemon_NAME ${CMAKE_PROJECT_NAME})
    endif()

    # if(IS_DIRECTORY ...) needs a full path
    webos_make_source_path_absolute(webos_daemon_LAUNCH files/launch/${webos_daemon_NAME} TRUE)

    _webos_set_bin_inst_dir(destdir TRUE ${webos_daemon_ROOTFS})
    _webos_set_bin_permissions(permissions ${webos_daemon_RESTRICTED_PERMISSIONS})

    # XXX powerd had this -- is it necessary?
    # set_property(TARGET ${webos_daemon_NAME} PROPERTY INSTALL_RPATH_USE_LINK_PATH TRUE)

    install(TARGETS ${webos_daemon_NAME} DESTINATION ${destdir} ${permissions})

    if(IS_DIRECTORY ${webos_daemon_LAUNCH})
        file(GLOB_RECURSE src_absfiles ${webos_daemon_LAUNCH}/*.in)
    else()
        set(src_absfiles "")
        if(EXISTS ${webos_daemon_LAUNCH}.in)
            set(src_absfiles ${webos_daemon_LAUNCH}.in)
        endif()
        if(EXISTS ${webos_daemon_LAUNCH}.conf.in)
            set(src_absfiles ${src_absfiles} ${webos_daemon_LAUNCH}.conf.in)
        endif()
    endif()

    if("${src_absfiles}" STREQUAL "")
        message(FATAL_ERROR "webos_build_daemon(): No .in files found under '${webos_daemon_LAUNCH}'")
    endif()

    foreach(file ${src_absfiles})
        string(REGEX REPLACE "\\.in$" "" file_noext ${file})
        if (${file} MATCHES ".*\\.conf\\.in$")
            webos_build_configured_file(${file_noext} SYSCONFDIR "init")
        else()
            webos_build_configured_file(${file_noext} SYSCONFDIR "event.d")
        endif()
    endforeach()
endfunction()


# Usage: webos_build_library([NAME <name>] [TARGET <target-name>] [NOHEADERS | HEADERS <path-to-headers>] [RESTRICTED_PERMISSIONS])
#
# <name> defaults to CMAKE_PROJECT_NAME. If you passed something other than <name> as the first argument to add_library(), you must
# specify it using the TARGET option.
# If <path-to-headers> is relative, CMAKE_SOURCE_DIR is prepended; default <path-to-headers> is "include/public". The tree under
# <path-to-headers> is installed under WEBOS_INSTALL_INCLUDEDIR.
# Note that HEADERS and NOHEADERS are mutually exclusive.
# TODO: check if using GenerateExportHeader module would be useful
function(webos_build_library)
	cmake_parse_arguments(webos_library "RESTRICTED_PERMISSIONS;NOHEADERS" "NAME;TARGET;HEADERS" "" ${ARGN})
	if(DEFINED webos_library_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "webos_build_library(): Unrecognized arguments: '${webos_library_UNPARSED_ARGUMENTS}'")
	endif()

	if(NOT DEFINED webos_library_NAME)
		set(webos_library_NAME ${CMAKE_PROJECT_NAME})
	endif()

	if(NOT DEFINED webos_library_TARGET)
		set(webos_library_TARGET ${webos_library_NAME})
	endif()

	if (webos_library_NOHEADERS)
		if (NOT "${webos_library_HEADERS}" STREQUAL "")
			message(FATAL_ERROR "webos_build_library(): Invalid arguments: both HEADERS and NOHEADERS found")
		endif()
	else()
		if(NOT DEFINED webos_library_HEADERS)
			set(webos_library_HEADERS include/public)
		endif()

		if(NOT IS_ABSOLUTE ${webos_library_HEADERS})
			set(webos_library_HEADERS ${CMAKE_SOURCE_DIR}/${webos_library_HEADERS})
		endif()
	endif()

	_webos_set_bin_permissions(permissions ${webos_library_RESTRICTED_PERMISSIONS})

	# If <target-name> begins with "lib", then the library name would begin with "liblib" unless its fixed, which is done here.
	# NB. Can't just get the LIBRARY_OUTPUT_NAME properity, because it doesn't exist unless it's been assigned to (it doesn't
	#     have a default value).
	get_target_property(location ${webos_library_TARGET} LOCATION)
	string(REGEX MATCH "[^/]+$" libname ${location})
	string(SUBSTRING ${libname} 0 6 libnameprefix)
	if(${libnameprefix} STREQUAL liblib)
		# ASSERT(PREFIX is "lib")
		set_target_properties(${webos_library_TARGET} PROPERTIES PREFIX "")
	endif()

	# Why can't install() figure this out without needing to be told?
	if(UNIX)
		if(${location} MATCHES "\\.a$")
			set(kind ARCHIVE)
			# Allow static libraries to be linked into shared ones. Without -fPIC, you can get this errors such as:
			#   libXXX.a(YYY.o): relocation R_ARM_MOVW_ABS_NC against `a local symbol' can not be used when making a
			#                    shared object; recompile with -fPIC
			# Technically, it's not needed for x86, but supplying it does no harm.
			set_target_properties(${webos_library_TARGET} PROPERTIES COMPILE_FLAGS -fPIC)
		elseif(${location} MATCHES "\\.so$")
			set(kind LIBRARY)
		else()
			message(FATAL_ERROR "webos_build_library(): Unrecognized library suffix: ${location}")
		endif()
	else()
		message(FATAL_ERROR "INTERNAL ERROR: webos_build_library() needs work for non-UNIX builds.")
	endif()

	set_target_properties(${webos_library_TARGET} PROPERTIES VERSION ${WEBOS_API_VERSION} SOVERSION ${WEBOS_API_VERSION_MAJOR})
	install(TARGETS ${webos_library_TARGET} ${kind} DESTINATION ${WEBOS_INSTALL_LIBDIR} ${permissions})

	# Must include a trailing "/" on the webos_library_HEADERS expansion to avoid
	# installing the actual directory.
	#
	# install(DIRECTORY include DESTINATION /usr/include/<name> ...) puts the headers in /usr/include/<name>/include/*.h
	# install(DIRECTORY include/ DESTINATION /usr/include/<name> ...) puts the headers in /usr/include/<name>/*.h
	#
	# Just to avoid any unpleasant surprises, remove any trailing '/' from the provided path first

	if (NOT webos_library_NOHEADERS)
		string(REGEX REPLACE "/+$" "" webos_library_HEADERS ${webos_library_HEADERS})
		install(DIRECTORY ${webos_library_HEADERS}/
		        DESTINATION ${WEBOS_INSTALL_INCLUDEDIR}
		        FILES_MATCHING PATTERN "*"
		        PATTERN ".*" EXCLUDE
		        PATTERN "*.in" EXCLUDE)
	endif()
endfunction()


# Usage: include(FindPkgConfig)
#        ...
#        pkg_check_modules(NODEJS REQUIRED nodejs)
#        include_directories(${NODEJS_INCLUDE_DIRS})
#        webos_add_compiler_flags(ALL ${NODEJS_CFLAGS_OTHER})
#        ...
#        add_executable(<module-basename>.node <sources>)
#        target_link_libraries(<module-basename>.node ${NODEJS_LIBRARIES})
#        ...
#        webos_build_nodejs_module([NAME <module-basename>])
#
# Builds the nodejs module <module-basename>.node and installs it under WEBOS_INSTALL_LIBDIR/nodejs. <module-basename>> defaults
# to CMAKE_PROJECT_NAME.
function(webos_build_nodejs_module)
	cmake_parse_arguments(webos_nodejs_module "" "NAME" "" ${ARGN})
	if(DEFINED webos_nodejs_module_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "webos_build_nodejs_module(): Unrecognized arguments: '${webos_nodejs_module_UNPARSED_ARGUMENTS}'")
	endif()

	if(NOT DEFINED webos_nodejs_module_NAME)
		set(webos_nodejs_module_NAME ${CMAKE_PROJECT_NAME})
	endif()

	if(${webos_nodejs_module_NAME} MATCHES "\\.node$")
		message(FATAL_ERROR "webos_build_nodejs_module(): value for the NAME option or project name must not end with '.node': ${webos_nodejs_module_NAME}")
	endif()

	_webos_set_bin_permissions(permissions FALSE)
	install(TARGETS ${webos_nodejs_module_NAME}.node DESTINATION ${WEBOS_INSTALL_LIBDIR}/nodejs ${permissions})
endfunction()


# Usage: _webos_add_doc_target(<doc_dir> <doxyfile> [basename])
#
# Add a new doc target for the given doxyfile
#
# The optional argument basename needs to be passed in case of
# multiple doxygen files
 
function(_webos_add_doc_target doc_dir doxyfile)
	webos_make_source_path_absolute(doc_dir ${CMAKE_SOURCE_DIR}/doc TRUE)
	file(RELATIVE_PATH doc_reldir ${CMAKE_SOURCE_DIR} ${doc_dir})

	unset(basename)
	unset(all_flag)
	if(${ARGC} EQUAL 2)
		set(target docs)
		if(WEBOS_CONFIG_BUILD_DOCS)
			set(all_flag ALL)
		endif()
	else()
		set(basename ${ARGV2})
		set(target docs-${basename})
	endif()

	set(outdir ${WEBOS_BINARY_DOCUMENTATION_DIR}/${CMAKE_PROJECT_NAME}/${basename})

	set(configuredfile ${WEBOS_BINARY_CONFIGURED_DIR}/${doc_reldir}/${doxyfile})
	configure_file(${doc_dir}/${doxyfile}.in ${configuredfile} @ONLY)

	# Ensure that the expected HTML is generated
	file(APPEND ${configuredfile} "GENERATE_HTML = YES\n")
	# Ensure that the output is generated in the expected location
	file(APPEND ${configuredfile} "OUTPUT_DIRECTORY = ${outdir}\n")
	# Ensure that CMAKE_BINARY_DIR isn't searched for input (in case INPUT is CMAKE_SOURCE_DIR and CMAKE_BINARY_DIR is a
	# subdirectory of it).
	file(APPEND ${configuredfile} "EXCLUDE = ${CMAKE_BINARY_DIR}\n")

	add_custom_target(${target} ${all_flag}
	                  COMMAND mkdir -p ${outdir}
	                  COMMAND cd ${outdir}
	                  COMMAND doxygen ${configuredfile}
	                  SOURCES ${doc_dir}/${doxyfile}.in
	                  COMMENT "Generating ${basename} Doxygen documentation")

	if(${ARGC} GREATER 2)
		add_dependencies(docs ${target})
	endif()
endfunction()

# Usage: webos_config_build_doxygen(<doc-dir> <doxyfile> ...)
#
# Adds a "docs" make target that builds HTML Doxygen documentation having first done a configure_file() on 
# <doxyfile>.in. Multiple <doxyfile> arguments can be specified.
#
# If <doc-dir> is relative, CMAKE_SOURCE_DIR is prepended.
#
# If WEBOS_CONFIG_BUILD_DOCS is set, adds the custom target as a dependency of "make all" and arranges for "make install" to
# install what's generated.
#

function(webos_config_build_doxygen doc_dir)
	if(${ARGC} EQUAL 2)
		set(single_doxyfile TRUE)
	elseif(${ARGC} LESS 2)
		message(FATAL_ERROR "webos_config_build_doxygen(): Invalid argument list: '${ARGN}'")
	endif()

	set(outdir ${WEBOS_BINARY_DOCUMENTATION_DIR}/${CMAKE_PROJECT_NAME})

	message(STATUS "Adding \"docs\" make target to build configured ${doc_dir}/${doxyfile}.in")
	if(WEBOS_CONFIG_BUILD_DOCS)
		message(STATUS "Making \"make docs\" a dependency of \"make all\"")
		set(all_flag ALL)
	
		find_program(DOXYGEN_EXECUTABLE NAMES doxygen DOC "doxygen executable")
		find_program(DOT_EXECUTABLE NAMES dot DOC "dot executable")
		if(NOT (DOXYGEN_EXECUTABLE OR DOT_EXECUTABLE))
			message(FATAL_ERROR "In order to generate documentation, please install 'doxygen' and 'graphviz'")
		elseif(NOT DOXYGEN_EXECUTABLE)
			message(FATAL_ERROR "In order to generate documentation, please install 'doxygen'")
		elseif(NOT DOT_EXECUTABLE)
			message(FATAL_ERROR "In order to generate documentation, please install 'graphviz'")
		endif()
	else()
		message(STATUS "Output will be written to ${outdir}")
		set(all_flag "")
	endif()

	if(NOT single_doxyfile)
		add_custom_target(docs ${all_flag})
	endif()
	
	webos_make_source_path_absolute(doc_dir ${CMAKE_SOURCE_DIR}/doc TRUE)
	file(RELATIVE_PATH doc_reldir ${CMAKE_SOURCE_DIR} ${doc_dir})

	foreach(file ${ARGN})
		if(single_doxyfile)
			unset(basename)
		else()
			get_filename_component(basename ${file} NAME_WE)
		endif()
		_webos_add_doc_target(${doc_dir} ${file} ${basename})
	endforeach()

	if(WEBOS_CONFIG_BUILD_DOCS)
		install(DIRECTORY ${outdir} DESTINATION ${WEBOS_INSTALL_DOCDIR})
		message(STATUS "Adding installation of documentation to \"make install\"")
	else()
		message(STATUS "Adding \"install-docs\" make target to install ${outdir}")

		# The 'chmod' is to emulate the permissions set by the cmake install(DIRECTORY ...) command
		add_custom_target(install-docs
		                  COMMAND mkdir -p ${WEBOS_INSTALL_DOCDIR}
		                  COMMAND cp -r ${outdir} ${WEBOS_INSTALL_DOCDIR}
		                  COMMAND chmod -R u=rwX,g=rX,o=rX ${WEBOS_INSTALL_DOCDIR}/${CMAKE_PROJECT_NAME}
		                  DEPENDS docs
		                  COMMENT "Installing Doxygen documentation to ${WEBOS_INSTALL_DOCDIR}/${CMAKE_PROJECT_NAME}")
		endif()

endfunction()


# Usage: webos_install_symlink(<target> <link>)
function(webos_install_symlink target link)
	# cmake -E create_symlink doesn't overwrite LINK, so use non-portable ln -snf until we have to worry about it
	install(CODE "message(\"-- Installing: symlink \$ENV{DESTDIR}${link} -> ${target}\")")
	install(CODE "execute_process(COMMAND ln -snf ${target} \$ENV{DESTDIR}${link})")
	# XXX Why doesn't this work?
	install(CODE "file(APPEND ${CMAKE_BINARY_DIR}/install_manifest.txt \"\$ENV{DESTDIR}${link}\")")
endfunction()


# XXX Eventually support <oper> = REMOVE_ITEM
macro(_webos_manipulate_flags oper lang build_type)
	set(_var CMAKE_${lang}_FLAGS)
	if((${build_type} STREQUAL DEBUG) OR (${build_type} STREQUAL RELEASE))
		set(_var ${_var}_${build_type})
	endif()
	if(DEFINED ${_var})
		# Convert  ARGN into a multi-word string
		string(REPLACE ";" " " _argn_str "${ARGN}")
		set(${_var} "${${_var}} ${_argn_str}")
		unset(_argn_str)
	endif()
	unset(_var)
endmacro()


macro(webos_add_compiler_flags build_type)
	if((${build_type} STREQUAL ALL) OR (${build_type} STREQUAL DEBUG) OR (${build_type} STREQUAL RELEASE))
		_webos_manipulate_flags(APPEND C ${build_type} ${ARGN})
		_webos_manipulate_flags(APPEND CXX ${build_type} ${ARGN})
	else()
		message(FATAL_ERROR "webos_add_compiler_flags(): Invalid <build_type> argument provided: '${build_type}'")
	endif()
endmacro()


macro(webos_add_linker_options build_type)
	if((${build_type} STREQUAL ALL) OR (${build_type} STREQUAL DEBUG) OR (${build_type} STREQUAL RELEASE))
		# XXX Appending to CMAKE_EXE_LINKER_FLAGS fails to add them to the link command line -- why?
		# So, convert to gcc flags by prepending "-Wl," and converting any spaces into commas
		# Note that using add_definitions() also fails to add to the link command line.
		foreach(_opt ${ARGN})
			string(REPLACE " " "," _gcc_opt "${_opt}")
			webos_add_compiler_flags(${build_type} -Wl,${_gcc_opt})
		endforeach()
		unset(_opt)
		unset(_gcc_opt)
	else()
		message(FATAL_ERROR "webos_add_linker_options(): Invalid <build_type> argument provided: '${build_type}'")
	endif()
endmacro()


# Also creates a WEBOS_TARGET_* global variable
macro(_webos_add_target_define name default)
	if(NOT DEFINED ${name})
		set(${name} ${default})
	endif()
	string(TOUPPER ${${name}} _define_suffix)
	message(STATUS "Adding -D${name}_${_define_suffix}")
	webos_add_compiler_flags(ALL -D${name}_${_define_suffix})
	unset(_define_suffix)
endmacro()


macro(webos_core_os_dep)
	# Default WEBOS_TARGET_CORE_OS for Ubuntu desktop build is "ubuntu"
	_webos_add_target_define(WEBOS_TARGET_CORE_OS ubuntu)
endmacro()


macro(webos_machine_dep)
	# Default WEBOS_TARGET_MACHINE for Ubuntu desktop build is "standalone"
	_webos_add_target_define(WEBOS_TARGET_MACHINE standalone)
endmacro()


macro(webos_machine_impl_dep)
	# Default WEBOS_TARGET_MACHINE_IMPL for Ubuntu desktop build is "simulator"
	_webos_add_target_define(WEBOS_TARGET_MACHINE_IMPL simulator)
endmacro()


function(_webos_check_install_dir caller install_dir_moniker install_subdir outvar)
	if ("${install_dir_moniker}" STREQUAL "")
		message(FATAL_ERROR "${caller}(): Empty <install-dir-moniker> provided")
	elseif(${install_dir_moniker} STREQUAL ROOT)
		message(FATAL_ERROR "${caller}(): Cannot specify ROOT for <install-dir-moniker>")
	endif()

	if("${WEBOS_INSTALL_${install_dir_moniker}}" STREQUAL "")
		message(FATAL_ERROR
		        "${caller}():"
		        " Unknown WEBOS_INSTALL_ directory name provided: '${install_dir_moniker}'")
	endif()

	set(installdir ${WEBOS_INSTALL_${install_dir_moniker}})

	# Ensure any directory name is not absolute. An empty string installs
	# directly into WEBOS_INSTALL_<install-dir-moniker>.
	if(NOT "${install_subdir}" STREQUAL "")
		if(IS_ABSOLUTE ${install_subdir})
			message(FATAL_ERROR
			        "${caller}():"
			        " Absolute path specified for installation subdirectory: '${install_subdir}'")
		elseif(${install_subdir} MATCHES "^\\.\\./")
			message(FATAL_ERROR
			        "${caller}():"
			        " Installation subdirectory must not begin with '../': '${install_subdir}'")
		endif()
		set(installdir ${installdir}/${install_subdir})
	endif()

	set(${outvar} ${installdir} PARENT_SCOPE)
endfunction()


# Usage: webos_build_configured_file(<path-to-basename> <install-dir-moniker> <install-subdir>)
#
# Configures file <path-to-basename>.in and installs the resulting file in WEBOS_INSTALL_<install-dir-moniker>/<install-subdir>.
# If <path-to-basename> is relative, CMAKE_SOURCE_DIR is prepended. <install-subdir> must not be absolute nor can it begin with
# "../". An empty string will install the files directly under WEBOS_INSTALL_<install-dir-moniker> .
function(webos_build_configured_file basename install_dir_moniker install_subdir)
	_webos_check_install_dir(webos_build_configured_file "${install_dir_moniker}" "${install_subdir}" installdir)

	webos_make_source_path_absolute(basename "" TRUE)
	file(RELATIVE_PATH basename_relpath ${CMAKE_SOURCE_DIR} ${basename})
	set(configuredfile ${WEBOS_BINARY_CONFIGURED_DIR}/${basename_relpath})

	# XXX Ideally, ${configuredfile} would be read-only so that developers don't accidentally modify it
	configure_file(${basename}.in ${configuredfile} @ONLY)
	install(FILES ${configuredfile} DESTINATION ${installdir})
endfunction()


# Internal routine to configure the directory tree <abs-tree>, writing the results under WEBOS_BINARY_CONFIGURED_DIR, and
# optionally install it under WEBOS_INSTALL_<install-dir-moniker>/<install-subdir>. <abs-tree> is expected to be an absolute path.
# If <do-install> is FALSE, <install-dir-moniker> and <install-subdir> are ignored (although they must be present).
function(_webos_configure_tree caller do_install abs_tree install_dir_moniker install_subdir)
	# First two arguments are supplied by us, so assume they don't need to be checked

	if(do_install)
		_webos_check_install_dir(${caller} "${install_dir_moniker}" "${install_subdir}" installdir)
	endif()

	file(GLOB_RECURSE src_absfiles ${abs_tree}/*.in)
	if("${src_absfiles}" STREQUAL "")
		message(FATAL_ERROR "${caller}(): No .in files found under '${abs_tree}'")
	endif()

	foreach(file ${src_absfiles})
		string(REGEX REPLACE "\\.in$" "" file_noext ${file})
		file(RELATIVE_PATH dest_relpath ${CMAKE_SOURCE_DIR} ${file_noext})
		set(dest_abspath ${WEBOS_BINARY_CONFIGURED_DIR}/${dest_relpath})
		# XXX Ideally, ${dest_abspath} would be read-only so that developers don't accidentally modify it
		configure_file(${file} ${dest_abspath} @ONLY)
	endforeach()

	if(do_install)
		file(RELATIVE_PATH dest_reltree ${CMAKE_SOURCE_DIR} ${abs_tree})
		set(dest_abstree ${WEBOS_BINARY_CONFIGURED_DIR}/${dest_reltree})
		install(DIRECTORY ${dest_abstree}/ DESTINATION ${installdir})
	endif()
endfunction()


# Usage: webos_build_configured_tree(<path-to-dir> <install-dir-moniker>)
#
# Configures all the *.in files found under <path-to-dir> and installs the resulting tree under WEBOS_INSTALL_<install-dir-moniker>.
# If <path-to-dir> is relative, CMAKE_SOURCE_DIR is prepended.
function(webos_build_configured_tree tree install_dir_moniker)
	webos_make_source_path_absolute(headers_tree "" TRUE)
	_webos_configure_tree(webos_build_configured_tree TRUE ${tree} ${install_dir_moniker} "")
endfunction()


# Usage: webos_build_pkgconfig([<path-to-basename>])
#
# Configures file <path-to-basename>.pc.in and installs resulting the <path-to-basename>.pc in the pkgconfig directory.
# If <path-to-basename> is relative, CMAKE_SOURCE_DIR is prepended.
# <path-to-basename> defaults to ${CMAKE_SOURCE_DIR}/pkgconfig/${CMAKE_PROJECT_NAME}
function(webos_build_pkgconfig)
	if(ARGC LESS 1)
		set(basename_path "")
	elseif(ARGC EQUAL 1)
		set(basename_path ${ARGV0})
	else()
		message(FATAL_ERROR "webos_build_pkgconfig(): invalid argument list: '${ARGN}'")
	endif()

	if("${basename_path}" STREQUAL "")
		set(basename_path files/pkgconfig/${CMAKE_PROJECT_NAME})
	endif()

	webos_build_configured_file(${basename_path}.pc PKGCONFIGDIR "")
endfunction()


function(_webos_install_system_bus_files source_path ftype visibility dest_path)

	# First configure and install all *.in files
	file(GLOB filelist ${source_path}/*.${ftype}.${visibility}.in)

	foreach(sysfile ${filelist})
		string(REGEX REPLACE "\\.${visibility}\\.in$" "" destfile ${sysfile})
		get_filename_component(destfile ${destfile} NAME)

		# Can't use build_configured file because we rename the file during the configure
		set(configured_file ${WEBOS_BINARY_CONFIGURED_DIR}/files/sysbus/${destfile}.${visibility})
		# XXX Ideally, ${configured_file} would be read-only so that developers don't accidentally modify it
		configure_file(${sysfile} ${configured_file})
#		message(STATUS "${configured_file} will be installed to ${WEBOS_INSTALL_SYSBUS_${dest_path}}/${destfile}")
		install(FILES ${configured_file} DESTINATION ${WEBOS_INSTALL_SYSBUS_${dest_path}} RENAME ${destfile})
	endforeach()

	# Next, install any files not requiring configuration
	file(GLOB filelist ${source_path}/*.${ftype}.${visibility})

	foreach(sysfile ${filelist})
		# Remove the visibility component of the filename
		string(REGEX REPLACE "\\.${visibility}$" "" destfile ${sysfile})
		get_filename_component(destfile ${destfile} NAME)
		# Install the file, renaming it to remove the visibility component
		install(FILES ${sysfile} DESTINATION ${WEBOS_INSTALL_SYSBUS_${dest_path}} RENAME ${destfile})
	endforeach()
endfunction()


# Usage: webos_build_system_bus_files([<path-to-system-bus-files>])
#
# Install a system bus service's service and role files <path-to-system-bus-files> 
# defaults to ${CMAKE_SOURCE_DIR}/files/sysbus
function(webos_build_system_bus_files)
	if(ARGC LESS 1)
		set(source_path files/sysbus)
	elseif(ARGC EQUAL 1)
		set(source_path ${ARGV0})
	else()
		message(FATAL_ERROR "webos_build_system_bus_files(): invalid argument list: '${ARGN}'")
	endif()

	webos_make_source_path_absolute(source_path files/sysbus TRUE)

	_webos_install_system_bus_files(${source_path} service pub PUBSERVICESDIR)
	_webos_install_system_bus_files(${source_path} service prv PRVSERVICESDIR)
	_webos_install_system_bus_files(${source_path} json pub PUBROLESDIR)
	_webos_install_system_bus_files(${source_path} json prv PRVROLESDIR)
endfunction()


# Usage: webos_build_db8_files([path-to-db-tree])
#
# Install the "kinds" and "permissions" files for a component that uses db8
# <path-to-db-tree> points to a directory containing "kinds" and a "permissions" subdirectories
# defaults to ${CMAKE_SOURCE_DIR}/files/db8
function(webos_build_db8_files)
	if(ARGC LESS 1)
		set(source_path files/db8)
	elseif(ARGC EQUAL 1)
		set(source_path ${ARGV0})
	else()
		message(FATAL_ERROR "webos_build_db8_files(): invalid argument list: '${ARGN}'")
	endif()

	webos_make_source_path_absolute(source_path files/db TRUE)
	file(GLOB kindFiles ${source_path}/kinds/com.*)
	file(GLOB permFiles ${source_path}/permissions/com.*)
	install(FILES ${kindFiles} DESTINATION ${WEBOS_INSTALL_WEBOS_SYSCONFDIR}/db/kinds)
	install(FILES ${permFiles} DESTINATION ${WEBOS_INSTALL_WEBOS_SYSCONFDIR}/db/permissions)
endfunction()


# Usage: webos_configure_source_files(<list-var> <path-to-source-file> ...)
#
# Configures <path-to-source-file>.in, writing the processed output to the corresponding location under
# WEBOS_BINARY_CONFIGURED_DIR, and appends the paths of the processed file to the list
# variable <list-var>. If <path-to-source-file> is a relative path, CMAKE_CURRENT_SOURCE_DIR is prepended.
#
# Example usage:
#
#   include_directories( ... )
#   list(APPEND sourcelist src/file1.c src/files2.c ... )
#   webos_configure_source_files(sourcelist src/file3.c src/file4.c ... )  # configures src/file3.c.in and src/file4.c.in
#   add_executable(${CMAKE_PROJECT_NAME} ${sourcelist})
#   link_target_libraries(${CMAKE_PROJECT_NAME} ... )
#   webos_build_program()
#
function(webos_configure_source_files list_var)
	set(local_list ${${list_var}})
	foreach(file ${ARGN})
		_webos_make_path_absolute(${CMAKE_CURRENT_SOURCE_DIR} file "" TRUE)
		file(RELATIVE_PATH dest_relpath ${CMAKE_SOURCE_DIR} ${file})
		set(dest_abspath ${WEBOS_BINARY_CONFIGURED_DIR}/${dest_relpath})
		# XXX Ideally, ${dest_abspath} would be read-only so that developers don't accidentally modify it
		configure_file(${file}.in ${dest_abspath} @ONLY)
		list(APPEND local_list ${dest_abspath})
	endforeach()
	set(${list_var} ${local_list} PARENT_SCOPE)
endfunction()


# Usage: webos_configure_header_files(<path-to-headers-tree> [INSTALL])
#
# Configures all of the *.in files found in the tree rooted at <path-to-headers-tree>, writing the processed output to the
# corresponding location under WEBOS_BINARY_CONFIGURED_DIR, and arranges for them to be added to the header search path used by the
# compiler.  If <path-to-headers-tree> is a relative path, CMAKE_SOURCE_DIR is prepended. It is an error for there not be at least
# one .in file under <path-to-headers-tree>. If the INSTALL option is given, they will also be installed under
# WEBOS_INSTALL_INCLUDEDIR. (This need to have a different function signature from webos_configure_source_files() so that the root
# to the tree to install under WEBOS_INSTALL_INCLUDEDIR can be determined.)
function(webos_configure_header_files headers_tree)
	if((${ARGC} EQUAL 2) AND ("${ARGV1}" STREQUAL "INSTALL"))
		set(do_install TRUE)
	elseif(${ARGC} EQUAL 1)
		set(do_install FALSE)
	else()
		message(FATAL_ERROR "webos_configure_header_files(): Invalid argument list: '${ARGN}'")
	endif()

	webos_make_source_path_absolute(headers_tree "" TRUE)
	_webos_configure_tree(webos_configure_header_files ${do_install} ${headers_tree} INCLUDEDIR "")

	file(RELATIVE_PATH dest_reltree ${CMAKE_SOURCE_DIR} ${headers_tree})
	set(dest_abstree ${WEBOS_BINARY_CONFIGURED_DIR}/${dest_reltree})
	include_directories(BEFORE ${dest_abstree})
endfunction()
