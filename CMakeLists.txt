project(com.github.philip-scott.spice-up)
cmake_minimum_required(VERSION 2.6)

if ($ENV{USER} STREQUAL "pbuilder" OR $ENV{USER} STREQUAL "buildd")
else ($ENV{USER} STREQUAL "pbuilder" OR $ENV{USER} STREQUAL "buildd")
    enable_testing(true)
endif ($ENV{USER} STREQUAL "pbuilder" OR $ENV{USER} STREQUAL "buildd")

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

include (GNUInstallDirs)

set (PKGDATADIR "${CMAKE_INSTALL_FULL_DATAROOTDIR}/${CMAKE_PROJECT_NAME}")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (RELEASE_NAME "TARS")
set (VERSION "0.7")
set (VERSION_INFO "Release")

add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
# disable C compiler warnings
add_definitions(-w)

set (PKG_DEPS
    granite>=5.2.3
    gee-0.8
    gtk+-3.0>=3.22.0
    json-glib-1.0
    gudev-1.0
    libevdev
    libsoup-2.4
    libarchive
)

set (VALA_DEPS
    granite
    gee-0.8
    gtk+-3.0
    json-glib-1.0
    gudev-1.0
    libevdev
    linux
    libsoup-2.4
    libarchive
)


find_package(PkgConfig)
pkg_check_modules (DEPS REQUIRED ${PKG_DEPS})

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES} -lm)
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.26.0" MINIMUM)

add_subdirectory (po)
add_subdirectory (schemas)
add_subdirectory (data)
add_subdirectory (src)
