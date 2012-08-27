Reference Guide to cmake-modules-webos
======================================

Introduction
------------
This file provides a guide to using the Open webOS CMake modules to create 
projects which work within Open webOS. It documents each function defined in 
the module, along with the variables and symbols exported.

Getting the Modules
-------------------

In order to use the modules, you need to have version 2.8.7 or later of CMake
installed on your desktop system, and of course have the modules installed. See
the _README.md_ file for instructions on this.

Preamble to a CMake File
------------------------

The name of each function in the module begins with the prefix webos. If you look
at the source code of the module and see functions whose name is prefixed with an
underscore (i.e. _webos), do not be tempted to use them. They are for internal
use and not guaranteed act the same, have the same interface, or even exist from
version to version.

The first five (executable) lines of the top level _CMakeLists.txt_ file **must**
be as follows:

	cmake_minimum_required(VERSION 2.8.7)
	project(<name> <lang> [<lang> ...])

	include(webOS/webOS)
	webos_modules_init(1 0 0 QUALIFIER RC2)
	webos_component(<major> <minor> <patch> \[QUALIFIER <value>>])

In order, these lines: specify the version of cmake-module-modules that you are 
using to write your CMakeLists.txt; tell CMake the name of, and programming 
languages used in, the project; make all of the _webos\_*_ functions available;
initialise the module, and specify the version used in developing your script; 
and, finally, specify the version of the project being built.

To check which version of cmake-modules-webos you have installed, and thus what
the argument for <tt>wbos_modules_init()<\tt> should be, enter the following at
the command line:

	$ cmake --help-module webOS/webOS

If you want to know more about the first three commands, or generally want to see
the help for any CMake command, enter the following at the command line:

	$ cmake --help-command <command>

You can get a list of CMake commands with

	$ cmake --help-command-list

Or even more generally

	$ cmake --help

Function Reference
------------------

This section lists the functions in alphabetical order (yes, I know they all
start with "webos"). Arguments for each function are provided in a style similar
to what you will see when browsing the help from CMake, namely:

- < name >: A descriptive name for a value which must be supplied
- UPPERCASE: a keyword, which must be provided as shown, and usually introduces
and optional argument.
- [ ... ] An optional argument or combination of keywords and values.
- < name > ...: A space separated list of one or more values, each of the same type.
- {A | B}: Mutually exclusive options in the argument list.

Generally, arguments introduced with an upper-case keyword can be provided in 
any order, but < name > style arguments must appear in the order shown(even if
optional). Thus:

	webos_example(<number> [{A | B <number> ...}] [TEXT value])

could be called in any of the following ways

	webos_example( 1 )
	webos_example( 2 A )
	webos_example( 3 TEXT "with spaces" word1 word2)
	webos_example( 4 B 1 2 3 )
	webos_example( 5 TEXT works A)
	webos_example( 6 TEXT also works B 3.14195 41)

but not

	webos_example()              # must supply a number
	webos_example(3 A B 1 2 3)   # A and B are mutually exclusive
	webos_example(A 3 TEXT nope) # Mandatory arguments 

###webos_add_compiler_flags
Add a flag to the _C_FLAGS_ and _CXX_FLAGS_ variables which CMake expands on 
the compiler command line. 

	webos_add_compiler_flags({ALL | RELEASE | DEBUG} <flag> ...)

- The first argument specifies the build type for which the options should be 
  used.
- Each flag argument represents a compiler flag to be passed through.

For example, the following call turns on all warnings and defined a conditional
compilation value.

	webos_add_compiler_flags(ALL -Wall -DUSE_OWN_MATH)

If no build type is provided, a fatal error will occur.

Do not use this to add either linker options, instead use _webos_add_linker_options_,
which takes care of adding the "-Wl," for you.

###webos_add_linker_options
Pass an option to the linker. 

	webos_add_linker_options({ALL | RELEASE | DEBUG} <flag> ...)

- The first argument specifies the build type for which the options should be 
  used.
- Each remaining flag argument represents an option to be passed through to
  the lninker.

For example, the following call insists that there be no unresolved symbols at the
end of the linking process.

	webos_add_linker_options(ALL --no-undefined)

Do not include the "-Wl," prefix.

Do not use this to add either libraries which a target depends on. Instead use 
the CMake command _target_link_libraries()_ which ensures the makefile has all
the correct interdependencies.

###webos_append_new_to_list
Append each new item in its argument list to the variable provided.

	webos_append_new_to_list(<variable-name> <item> ...)

- variable-name provides the **name** (not the value) of a list variable to
  which new values will be appended.
- item ... provides a space separated list of items to be appended to the list
variable.

This is a function we needed when writing the modules and thought might be 
occasionally useful to someone. This function takes one or more arguments then 
examines the provided list variable. Any argument which can not be found in the
list is appended to it. Duplicate entries in argument list will be added only 
once.

For example, the following fragment

	set(mylist 1 3 4 6 7 8)
	webos_append_new_to_list(mylist 4 2 6 9 "a string" 9 1 5)

Will set _mylist_ to "1;3;4;6;7;8;2;9;a string;5". The 2, 9, and 5 were new and 
thus added. Only one copy of the 9 was added. Note that lists are stored 
internally by CMake as semi-colon separated values.

One possible use for this is creating a list of unique filenames in a directory
tree. The Cmake _list()_ command can be used for more complex manipulation 
of lists.

###webos_build_configured_file
Configures a single file and installs the result in one of the defined Open webOS
installation directories.

    webos_build_configured_file(<path-to-basename> <install-dir-name> <install-subdir>)

- path-to-basename provides the path and stem for the file to be configured.
  Do not include the final ".in". The function appends that to ensure the 
  correct naming convention is used. If a relative path is given it is treated
  as being relative to the root of the project, not the current source directory.
  
- install-dir-name provides the final part of a WEBOS_INSTALL_* symbol (see
  below) which identifies the installation directory. This approach ensures only
  "approved" locations are used as installation targets. 
  
- install-subdir names any subdirectory under install-dir-name in which
  the configured file should be installed. This must be a relative name, and can
  not contain "../". It does not need to be only one level deep. Thus 
  "data/subdir1" is perfectly acceptable.

After configuration, the resulting file can be inspected prior to actually
running _make install_. All configured files turn up under the _Configured_
subdirectory of the build tree.

When _webos_modules_init()_ is invoked it defines a large number of variables,
each of which maps onto a location where files should be installed. Each variable's
name begins with WEBOS_INSTALL_. For this call, you pass in everything **after**
this prefix. See a later section for a description of the variables.

Note that he final argument is not optional. If you do not wish to specify a
sub-directory, provide an empty string ("") for the argument. 

For example, the following command configures a data file and installs it under
the Opoen webOS equivaent of /etc/fred.

    webos_build_configured_file(files/data/mydata SYSCONFDIR fred)

###webos_build_configured_tree
Configures and installs all files under a provided directory tree into one of the
defined Open webOS installation directories.

	webos_build_configured_tree(<tree> <install-dir-name>)
	
- tree provides the path to a directory treecontaining files to be configured.
  If a relative path is given it is treated as being relative to the root of the
  project, not the current source directory.
  
  Every file in the tree below this directory, whose filename matches the pattern
  _*.in_ will be configured and installed in the same relative location. Note that
  this search for files is **recursive**.
  
- install-dir-name provides the final part of a WEBOS_INSTALL_* symbol (see
  below) which identifies the installation directory. This approach ensures only
  "approved" locations are used as installation targets. 
  
After configuration, the resulting files can be inspected prior to actually
running _make install_. All configured files turn up under the _Configured_
subdirectory of the build tree.

When _webos_modules_init()_ is invoked it defines a large number of variables,
each of which maps onto a location where files should be installed. Each variable's
name begins with WEBOS_INSTALL_. For this call, you pass in everything **after**
this prefix. See a later section for a description of the variables.

Note that he final argument is not optional. If you do not wish to specify a
sub-directory, provide an empty string ("") for the argument. 

For example, the following command configures all .in files under the directory
files/data/mytree and installs them under the Open webOS equivaent of /etc,
repdocuing the directory structure below _files/data/mytree_.

    webos_build_configured_tree(files/data/mytree SYSCONFDIR)
	
###webos_build_daemon
Configures and installs the UPSTART file for a daemon.

    webos_build_daemon([NAME <name>] [LAUNCH <path-to-basename>] [ROOTFS] [RESTRICTED_PERMISSIONS])

- The _NAME_ argument provides the makefile target name for the daemon executable.
  If not provided this defaults to CMakePROJECT_NAME_ (the first argument to
  the _project()_ command at the start of the top-level _CMakeLists.txt_ file).
  
- The _LAUNCH_ argument provides the path to the template UPSTART file, not
  including the ".in" suffix. This is the file which will be configured. If not
  provided, it defaults to _files/launch/CMAKE_PROJECT_NAME_, or _files_launch_${name}_.

  If the provided path identifies a directory, rather than a single file, then
  all _*.in_ files in that directory will be configured and installed to the
  relevant UPSTART configuration directory.

  If a relative path is provided, it is treated as relative to the root of the
  project, not the current source directory.
  
- Specify _ROOTFS_ to install the executable under WEBOS_INSTALL_BASE_SBINDIR 
  instead of WEBOS_INSTALL_SBINDIR.

- Specify _RESTRICTED_PERMISSIONS_ to restrict access to OWNER only. Otherwise
  READ and EXECUTE access will also be granted to "WORLD" and "GROUP".

Note that calling _webos_build_daemon()_ does not relieve you of the need to
include a CMake _add_executable()_ command. Also, note that _add_executable()_
must be invoked before _webos_build_daemon()_ (in order to define the target).

For example

    ...
    project(mydaemon C)
    ...
    add_executable(mydaemon FILES mydaemon.c)
    webos_build_daemon()

Will install the executable created by "make mydaemon" into the 
WEBOS_INSTALL_BINDIR location. It will also configure and install the UPSTART
script _files/launch/mydaemon.in_.

###webos_build_db8_files
Install all _kinds_ and _permissions_ files associated with _db8_.

    webos_build_db8_files([<path_to_db-tree>])

- path-to-db-tree provides a path to a directory which contains two further
subdirectories: _permissions_ and _kinds_. The function installs every file
matching the pattern "com.*" within these subdirectories them into
_WEBOS_INSTALL_WEBOS_SYSCONFDIR/db/kinds_ and _WEBOS_INSTALL_WEBOS_SYSCONFDIR/db/kinds_
respectively.

  If it is not provided, path-to-db-tree defaults to files/db8. 
  
  If a relative path is provided, it is treated as relative to the root of the
  project, not the current source directory.

These files do not generally contain any paths and are thus not configured.

###webos_build_library
Install a library and its associated headers.

    webos_build_library([NAME <name>]
                        [TARGET <target-name>]
                        [{NOHEADERS|HEADERS <path-to-headers>}]
                        [RESTRICTED_PERMISSIONS])

- Note that HEADERS and NOHEADERS are mutually exclusive

- name specifies the name of the library, without the "lib" prefix. If not
  provided, this defaults to CMAKE_PROJECT_NAME.

- target-name refers to the makefile target specified in the _add_library()_
  command. If not provided, this defaults to the value of the name argument,
  or CMAKE_PROJECT_NAME if that is not provided.

- Specify NOHEADERS to tell the function that there are no public header files
  to be installed. This is generally used when the library in question is a 
  plug-in, or perhaps a statically linked replacement for some standard functions
  (such as _malloc()_ and _free()_).
  
- Specify HEADERS to give a non-default path to a directory tree containing 
  public header files to be installed. This defaults to _include/public_ in
  the project root. 

- Specify _RESTRICTED_PERMISSIONS_ to restrict access to OWNER only. Otherwise
  READ and EXECUTE access will also be granted to "WORLD" and "GROUP".

This function is the real workhorse of the functions involved in reating 
libraries, as far as implementing conventions regarding library names, and
installation of headers.

The provision of both name and target-name arguments is intended to 
handle the case where the library either has a different name from that of the
overall CMake project, or where it is necessary to provide a different makefile
target name.

Consider the case of a daemon which also installs an API via a shared library.
For consistency, the daemon is called _mydaemon_ and the library _libmydaemon_.
CMake requires all target names to be globally unique within a project, so
you must provide a different target name for the library.

    project(mydaemon C)
    ...
    add_executable(mydaemon ...)
    webos_build_daemon()
    ...
    add_library(apilibrary SHARED ...)
    set_target_properties(apilibrary PROPERTIES OUTPUT_NAME mydaemon)
    ...
    webos_build_library(TARGET apilibrary)

Note that it was unnecessary to provide the NAME argument as the default of
CMAKE_PROJECT_NAME was correct, but the TARGET name **was** required. In the
case where both library and target names do not match, then both arguments are
required.

The convention for library include files in Open webOS is

- If a library installs a header file with the same name as the project (i.e.
  xxx.h for a library libxxx.so or libxxx.a), it can be installed directly into
  WEBOS_INSTALL_INCLUDEDIR. Though ideally it should be in a subdirectory.

- If a library installs multiple header files, or files with names which might
  clash with other installed headers (such as _json.h_, a **very** popular name),
  they must be installed in a subdirectory _WEBOS_INSTALL_INCLUDEDIR/xxx_.

- A combination of the two is possible, and likely. Often the top-level _xxx.h_
  file will be little more than a list of _#include_ statements pulling in all
  the headers in the subdirectory.

Because of these conventions, the HEADERS argument takes a path to a directory
which contains a **directory tree** to be installed. This defaults to 
_include/public_ in the project root, and thus should not normally need to be
installed - even when mutliple libraries are being installed.

Consider a project (admittedly fabricated to demonstrate a point) which installs
three libraries, each with a different set of headers. The libraries are called 
(imaginatively) mylib1, mylib2, and mylib3. The repsitory is structured thus

    include/public/
      mylib1.h
      mylib2.h
      mylib3.h
      mylib1/
         l1h1.h, l1h2.h, ...
      mylib2/
          l2h1.h, l2h2.h, ...
      mylib3/
         l3h1.h, l3h2.h, ...

The a project might look like this

    project(mylib C CXX)
    ...
    add_library(mylib1 ...)
    add_library(mylib2 ...)
    add_library(mylib3 ...)
    
    webos_build_library(NAME mylib1)
    webos_build_library(NAME mylib2 NOHEADERS)
    webos_build_library(NAME mylib3 NOHEADERS)

Note the use of NOHEADERS on the second and third calls to _webos_build_library_.
The first call installs everything under _include/public_. An alternative would 
have been to have a more complex structure within _include/public_ and install
each subtree along with its library. Note also that NAME argument **was**
needed on each call as none of the libraries was called _mylib_.
    
###webos_build_nodejs_module
Installs a nodejs module.

    webos_build_nodejs_module([NAME <module-basename>])

- The _NAME_ argument provides the **makefile target** name for the program 
  executable.
  
  If not provided this defaults to _CMAKE_PROJECT_NAME_ (the first argument to
  the _project()_ command at the start of the top-level _CMakeLists.txt_ file).
  
The _nodejs_ pkg-config data must be used in conjunction with 
webos_build_nodejs_module() as shown below:

    include(FindPkgConfig)
    ...
    pkg_check_modules(NODEJS REQUIRED nodejs)
    include_directories(${NODEJS_INCLUDE_DIRS})
    webos_add_compiler_flags(ALL ${NODEJS_CFLAGS_OTHER})
    ...
    add_executable(<module-basename>.node <sources>)
    target_link_libraries(<module-basename>.node ${NODEJS_LIBRARIES})
    ...
    webos_build_nodejs_module(NAME <module-basename>)

###webos_build_pkgconfig
Configure and install the pkg-config data file for a library project.

    webos_build_pkgconfig([<path-to-basename>])

- If provided, path-to-basename provides the full path (relative or absolute)
  to a file _path-to-basename.pc.in_

  If a relative path is provided, it is treated as relative to the root of the
  project, not the current source directory.

  If no path is given, it defaults to 
    CMAKE_SOURCE_DIR/files/pkgconfig/CMAKE_PROJECT_NAME.pc.in

Every library installed by a project is expected to also install a _pkg-config_
configuration file to assist other projects in finding it during their build.

A canonical example of such file follows:

    # <license block>
    
    libdir=@WEBOS_INSTALL_LIBDIR@
    includedir=@WEBOS_INSTALL_INCLUDEDIR@
    
    Name: @CMAKE_PROJECT_NAME@
    Description: @webos_component_SUMMARY@
    Version: @webos_component_VERSION@
    Libs: -L${libdir} -l@CMAKE_PROJECT_NAME@
    Cflags: -I${includedir}

Indeed, for any project which installs a single library, with the same name as
provided to the _CMake project()_ command, this is all that is needed.

For example,

    project <myjson CXX>
    ...
    webos_build_pkconfig()

will configure CMakeSOURCE_DIR/files/pkgconfig/myjson.pc.in_ and install the
configured file under _WEBOS_INSTALL_PKGCONFDIR_.

The argument tends to get used when your project installs more than one
library, perhaps providing bindings to multiple client languages. For example:

    project(myjson C CXX)
    ...
    add_library(myjson_c SHARED ...)
    add_library(myjson_cpp SHARED ...)
    ...
    webos_build_pkgconfig(files/pkgconfig/myjson_c)
    webos_build_pkgconfig(files/pkgconfig/myjson_cpp)

will configure and install two different pkg-config data files.

###webos_build_program
Configures and installs a console program.

    webos_build_program([NAME <name>] [ADMIN] [ROOTFS] [RESTRICTED_PERMISSIONS])

- The _NAME_ argument provides the **makefile target** name for the program 
  executable. Note that this is not necessarily the same as the executable's name.
  
  If not provided this defaults to CMakePROJECT_NAME_ (the first argument to
  the _project()_ command at the start of the top-level _CMakeLists.txt_ file).
  
- Specify ADMIN to install the executable under WEBOS_INSTALL_*SBINDIR instead 
  of WEBOS_INSTALL_*BINDIR

- Specify _ROOTFS_ to install the executable under WEBOS_INSTALL_ROOT instead of 
  WEBOS_INSTALL_PREFIX

- Specify _RESTRICTED_PERMISSIONS_ to restrict access to OWNER only. Otherwise
  READ and EXECUTE access will also be granted to "WORLD" and "GROUP".

Note that calling _webos_build_program()_ does not relieve you of the need to
include a CMake _add_executable()_ command. Also, note that _add_executable()_
must be invoked before _webos_build_program()_ (in order to define the target).

For example

    ...
    project(myapp C)
    ...
    add_executable(myapp FILES myapp.c)
    webos_build_program(ROOTFS ADMIN)

Will install the executable created by "make myapp" into the 
_WEBOS_INSTALL_BASE_SBINDIR_ location. 

###webos_build_system_bus_files
Configure and install the files associated with providing an interface over the
luna-service2 bus.

    webos_build_system_bus_files([<path-to-files>])
    
- path-to-files is a path to a directory containing the roles and service
  files to be installed. 

  If not provided, this defaults to CMakeSOURCE_DIR/files/sysbus_.

  If a relative path is provided, it is treated as relative to the root of the
  project, not the current source directory.

Any project which provides a _luna-service2_ interface is required to install
files to expose and describe that interface. This function installs those files.
Given that these files also often contain system paths, the files are configured
before being installed. The configured files can be inspected under the 
_Configured/files/sysbus_ subdirectory tree of the build directory.

All files in the provided directory which match one of the following patterns
will be configured and installed as shown below.

    Pattern             Installed in
    *.service.pub.in    WEBOS_INSTALL_SYSBUS_PUBSERVICESDIR
    *.service.prv.in    WEBOS_INSTALL_SYSBUS_PRVSERVICESDIR
    *.json.pub.in       WEBOS_INSTALL_SYSBUS_PUBROLESDIR
    *.json.prv.in       WEBOS_INSTALL_SYSBUS_PRVROLESDIR

No other files will be installed or configured. The last two projects of the
input file names (i.e. _.pub.in_ and _.prv.in_) are removed from the names of
the installed files.

###webos_component
Specify the version number for the Open webOS project being configured, and 
check that it matches the one expected if not being built standalone.

    webos_component(<major> <minor> <patch> [QUALIFIER <qualifier>])

- The three version number arguments are mandatory. Each argument must be a 
  non-negative integer value.

- The qualifier arguments allows the specification of a qualifier to the
  three part version number, such as rc1, rc2, alpha, or beta. It must contain
  only alphanumeric characters ([A-Za-z0-9])

The following variables and symbols are defined after calling this function:

    WEBOS_API_VERSION       The numeric version string of form _major.minor.patch_
    WEBOS_API_VERSION_MAJOR The major version only
    webos_component_VERSION The fully qualified project version string

For example,

    webos_component(1 2 3 QUALIFIER RC4)

would define the following variables

    WEBOS_API_VERSION       "1.2.3"
    WEBOS_API_VERSION_MAJOR "1"
    webos_component_VERSION "1.2.3~rc4"

Note that the qualifier is folded to lower case. Thus the QUALIFIER argument is
case-insensitive.

In a build system, it is expected that CMake will be invoked as 

    cmake -Dwebos_component_VERSION="major.minor.patch~qualifier" ..

In other words, the build system is expected to pass in the fully qualified
version of the project it is expecting to build. When this occurs, the call to
_webos_component_ ensures that the generated value for _webos_component_VERSION_
matches that on the command line and generates a fatal error if it does not.

###webos_config_build_doxygen
Create makefile targets for producing and installing _Doxygen_ documentation.

    webos_config_build_doxygen(<doc-dir> <doxygen-file>)

- doc-dir is a path to a directory containing the file _< doxygen-file >.in_

  If provided as an empty string, this defaults to CMakeSOURCE_DIR/files/doc_.

  If a relative path is provided, it is treated as relative to the root of the
  project, not the current source directory.

- ddoxygen-file is the stem of the Doxygen control file name, without the 
  final ".in" extension.

The provided _Doxygen_ file is first configured into a subdirectory of
_WEBOS_BINARY_DOCUMENTATION_DIR/CMAKE_PROJECT_NAME_. After this, a number of 
_Doxygen_ settings are overridden (GENERATE_HTML, OUTPUT_DIRECTORY, and
EXCLUDE) to ensure consistency in the results of the "make docs" target.

The generated makefiles will now contain two targets:

- _make docs_ which runs _Doxygen_ and produces the HTML output in the 
  _Documentation_ directory within the binary tree.

- _make install-docs_ which installs the generated documentation under
  _WEBOS_INSTALL_DOCDIR/CMAKE_PROJECT_NAME_.

  Note that running _make install-docs_ may require _sudo_ privileges.

This command does not currently take optional arguments.

Additionally, if the symbol _WEBOS_CONFIG_BUILD_DOCS_ is defined from the 
command line, the _docs_ and _install-docs_ targets will be added to _make all_
and _make install_ respectively. Otherwise, documentation must be generated and
installed via explicit _make_ commands.

###webos_configure_header_files
Configure all headers files in a directory tree and possibly install them.

    webos_configure_header_files(<headers-tree> [INSTALL])

- headers-tree provides a path to a directory-tree containing one or more
  ".in" files.
  
  If provided as an empty string, a fatal error will occur.

  If a relative path is provided, it is treated as relative to the root of the
  project, not the current source directory.

- Specify _INSTALL_ to arrange for all configured files to be installed under
  WEBOS_INSTALL_INCLUDEDIR.

Any file matching the glob "*.in" found in the tree rooted at headers-tree, 
will be configured for symbol expansion and the output will be placed in the
corresponding location under WEBOS_BINARY_CONFIGURED_DIR. Configured header 
files will be added to the header search path used by the compiler.

It is an error for there not be at least one ".in" file under headers-tree.

If the INSTALL option is given, the configured headers will also be installed
under WEBOS_INSTALL_INCLUDEDIR.

It becomes necessary to configure a header file if it contains any absolute paths
(usually as strings). To allow Open webOS to be installed in varying locations
as the need requires, each of these paths should be modified to use the
_WEBOS_INSTALL_*_ variables.

###webos_configure_source_files
Configure any source files and add the configured versions to a list variable.

    webos_configure_source_files(<list-var> <src-file> ...)

- list-var is the name of a list variable to which will be appended the
  absolute paths of all configured source files.

- src-file ... is a non-empty, space-seperated, list of source files to be
  configured.

The path to each src-file can be either relative or absolute. If a relative
path is provided, it is treated as relative to the current source directory.
**Note that this is different from every other function**

Each source file is configured to perform symbol replacement, and the absolute 
path to the output file is appended to _var_.

Thus, after calling _webos_configure_source_files()_, _var_ is suitable for
passing to _add_library_ or _add_executable_.

For example

    include_directories( ... )
    list(APPEND sourcelist src/file1.c src/files2.c ... )
    # configure src/file3.c.in and src/file4.c.in
    webos_configure_source_files(sourcelist src/file3.c src/file4.c ... )
    add_executable(${CMAKE_PROJECT_NAME} ${sourcelist})
    link_target_libraries(${CMAKE_PROJECT_NAME} ... )
    webos_build_program()

creates an executable from file1.c and file2.c, plus the configured 
versions of file43.c and file4.c.

###webos_core_os_dep
Adds a compiler flag and CMake symbol to indicate the core operatring system
being targeted

    webos_core_os_dep()

This function is intended to take the definition of _WEBOS_TARGET_CORE_OS_ from
the CMake command line (supplied via _-DWEBOS_TARGET_CORE_OS=<some value>_)
and pass it through to the compiler in a form suitable for conditional compilation.

After being invoked, _WEBOS_TARGET_CORE_OS_ is guaranteed to be defined. It will
either have the value supplied from the command line, or be set to "ubuntu". In
addition, a compiler flag will have been added of the form:

    -DWEBOS_TARGET_CORE_OS_<value>
    
For example, with a command line of
    cmake -DWEBOS_TARGET_CORE_OS=rockhopper
    
invoking _webos_core_os_dep_ will add the compiler flag
    -DWEBOS_TARGET_CORE_OS_ROCKHOPPER

allowing conditional code such as
    #ifdef WEBOS_TARGET_CORE_OS_UBUNTU
        // running stand-alone
    #else
        // Running on hardware
    #endif

_WEBOS_TARGET_CORE_OS_ can also be used to conditionalize actions within the 
CMake script itself, by testing it with _STREQUAL_.

###webos_install_symlink
Install a **symbolic** link during "make install".

    webos_install_symlink(<target> <link>)

- target specifies the existing file to be the target of the symbolic link.

- link specifies the name of the symbolic link.

Both arguments should be absolute paths, formed using the correct WEBOS_INSTALL
symbols. No validation is performed, and the installed link will not be added
to _install_manifest.txt_ in the binary tree.

**Use at your own risk**

###webos_machine_dep
Adds a compiler flag and CMake symbol to indicate the machine being targeted

    webos_machine_dep()

This function is intended to take the definition of _WEBOS_TARGET_MACHINE_ from
the CMake command line (supplied via _-DWEBOS_TARGET_MACHINE=<some value>_)
and pass it through to the compiler in a form suitable for conditional compilation.

After being invoked, _WEBOS_TARGET_MACHINE_ is guaranteed to be defined. It will
either have the value supplied from the command line, or be set to "standalone".
In addition, a compiler flag will have been added of the form:

    -DWEBOS_TARGET_MACHINE_<value>
    
For example, with a command line of

    cmake -DWEBOS_TARGET_MACHINE=qemux86
    
invoking _webos_machine_dep_ will add the compiler flag

    -DWEBOS_TARGET_MACHINE_QEMUX86

allowing conditional code such as

    #ifdef WEBOS_TARGET_MACHINE_QEMUX86
        // running on the emulator
    #else
        // Running on hardware
    #endif

_WEBOS_TARGET_MACHINE_ can also be used to conditionalize actions within the 
CMake script itself, by testing it with _STREQUAL_. 

For older projects, the following CMake commands will define the older
_MACHINE_<name>_ symbols () for the compiler.

    webos_machine_dep()
    include(webOS/LegacyDefine)
    ...
    # test WEBOS_TARGET_MACHINE to include or exclude specific files.
    ...

Thus, consider the following combination of CMake command-line (preceded by a 
"$" sign) and CMake **commands** (the rest of it):

    $ cmake -DWEBOS_TARGET_MACHINE=topaz # from the good old days
    
    webos_machine_dep()
    include(webOS/LegacyDefine)
    
    if(${WEBOS_TARGET_MACHINE} STREQUAL "topaz")
    #    add some source files for the touchpad
    endif()
    
Would add the following flags to the compiler command line

    -DWEBOS_TARGET_MACHINE_TOPAZ
    -DMACHINE_TOPAZ

###webos_machine_impl_dep
Adds a compiler flag and CMake symbol to indicate the target machine 
implementation, allowing conditionalizing of code and build scripts.

    webos_machine_impl_dep()

This function is intended to take the definition of _WEBOS_TARGET_MACHINE_IMPL_ from
the CMake command line (supplied via _-DWEBOS_TARGET_MACHINE_IMPL=<some value>_)
and pass it through to the compiler in a form suitable for conditional compilation.

The difference between the target MACHINE and the MACHINE_IMPL refers to the
logical target vs the actual implementation. The difference between a "machine
implementation" dependency on simulator and a core operating system dependency
is subtle: if there must be alternative behavior when when running on a host OS, 
e.g. simulating booting, then it's the former; if the dependency is on the 
presence of some project, e.g. X11, then it's the latter.

After being invoked, _WEBOS_TARGET_MACHINE_IMPL_ is guaranteed to be defined. It
will either have the value supplied from the command line, or be set to 
"simulator". In addition, a compiler flag will have been added of the form:

    -DWEBOS_TARGET_MACHINE_IMPL_<value>
    
For example, with a command line of

    cmake -DWEBOS_TARGET_MACHINE_IMPL=simulator
    
invoking _webos_machine_impl_dep_ will add the compiler flag

    -DWEBOS_TARGET_MACHINE_IMPL_SIMULATOR

_WEBOS_TARGET_MACHINE_IMPL_ can also be used to conditionalize actions within the 
CMake script itself, by testing it with _STREQUAL_.

For older projects, the following CMake commands will define the older
_TARGET_<name>_ symbols () for the compiler.

    webos_machine_impl_dep()
    include(webOS/LegacyDefine)
    ...
    # test WEBOS_TARGET_MACHINE_IMPL to include or exclude specific files.
    ...

Thus, consider the following combination of CMake command-line (preceded by a 
"$" sign) and CMake **commands** (the rest of it):

    $ cmake -DWEBOS_TARGET_MACHINE_IMPL=hardware
    
    webos_machine_dep()
    include(webOS/LegacyDefine)
    
Would add the following flags to the compiler command line

    -DWEBOS_TARGET_MACHINE_IMPL_HARDWARE
    -DTARGET_DEVICE

The following shows the mapping between machine implementation values and
legacy symbol names:

    value       New Symbol                           Legacy Symbol
    hardware    WEBOS_TARGET_MACHINE_IMPL_HARDWARE   TARGET_DEVICE
    vm          WEBOS_TARGET_MACHINE_IMPL_VM         TARGET_EMULATOR
    simulator   WEBOS_TARGET_MACHINE_IMPL_SIMULATOR  TARGET_DESKTOP

###webos_make_{binary|source}_path_absolute
Convert a relative path to an absolute path with respect to the root directory 
of the source or binary tree.

    webos_make_binary_path_absolute(<var> <default> <strip>)
    webos_make_source_path_absolute(<var> <default> <strip>)

- var is the **name** of a variable containing a possibly relative path.

- default provides a default value to use if var is an empty string

- specify strip as TRUE to remove any trailing slashes in var from the
  resultant absolute path, or FALSE to leave them as is.

These functions are used internally within the modules, usually to overcome the
interesting consequences of a CMake command line such as this:

    cmake -DWEBOS_INSTALL_ROOT=../../webosinstalls ..

which can end up with those ".."'s embedded in pkg-config files if not made
absolute. They are made public in case they should be useful to authors of 
CMake scripts.

Whilst the same effect can be achieved by the following CMake commands:

    set(var "../../INSTALL")
    set(var1 ${CMAKE_BINARY_DIR}/${var})

This will leave you with an absolute path something like:

    /home/<user>/projects/mylib/BUILD/../../INSTALL

whereas these functions do some magic to clean up the result, producing in the
above example

    webos_make_binary_path_absolute(var "INSTALL" TRUE)
    # sets 'var' to /home/<user>/projects/INSTALL
    # or /home/<user>/projects/mylib/BUILD/INSTALL if ${var} == ""

Note that, if the path is empty, we still get a sensible absolute path as a 
result.

###webos_modules_init 
Initialize the webOS CMake modules.

    webos_modules_init(<major> <minor> <patch> [QUALIFIER <qualifier>])

- The combined arguments define the version of the webOS CMake modules being used
  to write the current _CMakeLists.txt_ build script.

The correct version to specify can be found within _webOS/webOS.cmake_ following
the "@@@VERSION" tag, or by entering:

	$ cmake --help-module webOS/webOS

Once this function has been called, all of the WEBOS_INSTALL_* symbols will be
defined and available for use.

This function will generate fatal errors in the following circumstances:

- If CMake is invoked from the root of the project - i.e. you forgot to _cd_
  into a BUILD directory before invoking CMake.

- If there are any unexpected arguments.

- If the _major, minor, and patch_ parameters are not non-negative integers.

- If a specified QUALIFIER contains anything other alphanumeric characters.

- If the specified version is **newer** than that being used.

- If a README.md file exists, but does not contain a Summary subsection that is
  a single line.

This last one may seem strange, but enforces a convertion that all README.md 
files provide a simple one-line description of the project. This description is
extracted and stored in the variable _webos_component_SUMMARY_ for expansion in
places such as the Description field of pkg-config data files or in _Doxygen_ 
control files.

The Summary subsection should be formatted as follows:

    Summary
    -------
    <one line description>

Finally, the PKG_CONFIG_PATH environment variable will have a number of paths
appended to it to help ensure previously compoiled and installed Open webOS
projects can be found by the _pkg_check_modules()_ command. Open webOS
projects are typically installed in subtrees under _/usr/local_webos_ or
_/opt/webos_. 

During development, it is also common to install dependencies into a tree under
the user's home directory and provide a common override of _WEBOS_INSTALL_ROOT_
to all CMake command lines. For that reason, the provided path is also added
to _PKG_CONFIG_PATH_.

###webos_upstream_from_repo
Specify the version number for the FOSS project being configured, and check
that it matches the one expected (if WEBOS_COMPONENT_VERSION is passed in on the
command line).

    webos_upstream_from_repo(<upstream-version> <change-count>)

- upstream-version is a string identifying the version of the original
  project from which the internal fork was taken. The version is basically
  free format with the exception that the text before the first period must be a
  non-negative integer.
  
- change-count is a number indicating the number of changes made to the 
  original source code since forking. This must be a non-negative integer.
  
This function is called as an alternative to _webos_component()_ when the actual
project started life as an open source project and was modified during the
development of the original HP/Palm webOS platform.

Whereas _webos_component_ produces a _WEBOS_API_VERSION_ variable with the
format "9.9.9" or "9.9.9~xxx", this function produces one with the following
format

    "<upstream-version>-0webos<change-count>"
    
thus, a function call of _webos_upstream_from_repo(1.5-beta 23)_ defines the
following

    WEBOS_API_VERSION        1.5-beta-0webos23
    WEBOS_API_VERSION_MAJOR  1

In the exceptional case that _change-count_ is zero, _WEBOS_API_VERSION_ 
will not have anything appended. That is, it will have the same value as
_upstream-version_.

As with _webos_component()_ the calculated value of _webos_component_VERSION_ is
compared to any value of _webos_component_VERSION_ passed in from the command line.

WEBOS_INSTALL Variables
-----------------------


Other Global Variables
----------------------

