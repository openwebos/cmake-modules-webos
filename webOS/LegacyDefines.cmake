# - Adds legacy defines expected by older webOS components to the compiler flags
#
# Older webOS components expect MACHINE_<machine> and TARGET_<type> instead of
# WEBOS_TARGET_*
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
 
# webOS/LegacyDefines.cmake
 
if(DEFINED WEBOS_TARGET_MACHINE)
	string(TOUPPER ${WEBOS_TARGET_MACHINE} _upper)
	webos_add_compiler_flags(ALL -DMACHINE_${_upper})
	unset(_upper)
endif()

if(DEFINED WEBOS_TARGET_MACHINE_IMPL)
	if(${WEBOS_TARGET_MACHINE_IMPL} STREQUAL hardware)
		webos_add_compiler_flags(ALL -DTARGET_DEVICE)
	elseif(${WEBOS_TARGET_MACHINE_IMPL} STREQUAL vm)
		webos_add_compiler_flags(ALL -DTARGET_EMULATOR)
	elseif(${WEBOS_TARGET_MACHINE_IMPL} STREQUAL simulator)
		webos_add_compiler_flags(ALL -DTARGET_DESKTOP)
	endif()
endif()
