
include(ValaPrecompile)

SET(gtk_3_22 false CACHE BOOL "Beta Gtk 3.22 support")
if (gtk_3_22)
  set (GLOBAL_VALAC_OPTIONS ${GLOBAL_VALAC_OPTIONS} --define=GTK_3_22)
  message ("-- Gtk 3.22 support enabled")
endif (gtk_3_22)

vala_precompile(VALA_C
  Main.vala
  Application.vala
  Window.vala

  Services/Settings.vala
  Services/Slide.vala
  Services/SlideManager.vala
  Services/FileManager.vala
  Services/HistoryManager.vala
  Services/ImageHandler.vala
  Services/Utils.vala
  Services/GamepadSlideController.vala

  Widgets/Canvas.vala
  Widgets/ColorButton.vala
  Widgets/EntryCombo.vala
  Widgets/Headerbar.vala
  Widgets/SlideList.vala
  Widgets/DynamicToolbar.vala
  Widgets/Welcome.vala

  Widgets/CanvasItems/CanvasItem.vala
  Widgets/CanvasItems/TextItem.vala
  Widgets/CanvasItems/ColorItem.vala
  Widgets/CanvasItems/ImageItem.vala
  Widgets/CanvasItems/Grabber.vala

  Widgets/Toolbars/CanvasBar.vala
  Widgets/Toolbars/CommonBar.vala
  Widgets/Toolbars/ImageBar.vala
  Widgets/Toolbars/ShapeBar.vala
  Widgets/Toolbars/TextBar.vala
  Widgets/Toolbars/Toolbar.vala

  Widgets/Library/LibraryItem.vala
  Widgets/Library/Library.vala

  #${CMAKE_CURRENT_BINARY_DIR}/config.vala

  # LibGamepad
  Services/libgamepad/libgamepad.vala
  Services/libgamepad/gamepad-monitor.vala
  Services/libgamepad/gamepad.vala
  Services/libgamepad/helpers.vala
  Services/libgamepad/input-type.vala
  Services/libgamepad/raw-gamepad-interface.vala
  Services/libgamepad/raw-gamepad-monitor-interface.vala
  Services/libgamepad/standard-gamepad-axis.vala
  Services/libgamepad/standard-gamepad-button.vala

  Services/libgamepad/drivers/linux/guid-helpers.vala
  Services/libgamepad/drivers/linux/raw-gamepad.vala
  Services/libgamepad/drivers/linux/raw-gamepad-monitor.vala
PACKAGES
  ${VALA_DEPS}
OPTIONS
  ${GLOBAL_VALAC_OPTIONS}
  -g
  --thread
  --target-glib=2.38 # FIXME check before, and target the same version
  --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

include (gresource)
glib_compile_resources(GLIB_RESOURCES_ICONS SOURCE ../data/assets.gresource.xml)


add_executable(com.github.philip-scott.spice-up ${VALA_C} ${GLIB_RESOURCES_ICONS})

install(TARGETS com.github.philip-scott.spice-up RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})

add_subdirectory (Tests)
