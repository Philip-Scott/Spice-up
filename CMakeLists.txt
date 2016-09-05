project(spice-up)

cmake_minimum_required(VERSION 2.6)

# build UI lib
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# disable C compiler warnings
add_definitions(-w)

find_package(PkgConfig)

# either of webkitpackages would do

pkg_check_modules(DEPS REQUIRED
  granite>=0.3
  gtksourceview-3.0>=3.10
  gthread-2.0
  gtk+-3.0>=3.9.10
)

set (PKG_DEPS
 granite>=0.3
 gee-0.8
 gtk+-3.0
)

set (VALA_DEPS
 granite
 gee-0.8
 gtk+-3.0
)

pkg_check_modules (DEPS REQUIRED ${PKG_DEPS})

add_definitions(${DEPS_CFLAGS})

link_libraries(${DEPS_LIBRARIES})

link_directories(${DEPS_LIBRARY_DIRS})
link_directories(${CMAKE_BINARY_DIR})

include_directories(${CMAKE_BINARY_DIR})
include_directories(${CMAKE_SOURCE_DIR})

set (generated_resources ${generated_resource})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.26.0" MINIMUM)

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/spice-up")
set (GETTEXT_PACKAGE "spice-up")
set (RELEASE_NAME "TARS")
set (VERSION "0.7")
set (VERSION_INFO "Release")
set (CMAKE_C_FLAGS "-ggdb")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

add_subdirectory (po)
add_subdirectory (schemas)

include(ValaPrecompile)

vala_precompile(VALA_C
  src/Main.vala
  src/Application.vala
  src/Window.vala
  src/Canvas.vala
  src/CanvasItem.vala
  src/Services/Settings.vala
  src/Widgets/Headerbar.vala
  #src/config.vala
PACKAGES
  ${VALA_DEPS}
OPTIONS
  ${GLOBAL_VALAC_OPTIONS}
 -g
  --vapidir=${CMAKE_SOURCE_DIR}/vapi
  --thread
  --target-glib=2.38 # FIXME check before, and target the same version
)

add_executable(spice-up ${VALA_C} ${generated_resources})

install(TARGETS spice-up RUNTIME
  DESTINATION bin)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/Spice-up.desktop
  DESTINATION ${DATADIR}/applications/)

#install assets
file(GLOB assets "${CMAKE_CURRENT_SOURCE_DIR}/data/assets/*")
install (FILES ${assets}
  DESTINATION ${DATADIR}/spice-up/)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/data/spice.svg"
  DESTINATION ${DATADIR}/pixmaps/)

