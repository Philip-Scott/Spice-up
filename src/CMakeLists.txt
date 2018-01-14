
include(ValaPrecompile)

pkg_check_modules (GTK_3_22 QUIET gtk+-3.0>=3.20)
if (GTK_3_22_FOUND)
  set (GLOBAL_VALAC_OPTIONS ${GLOBAL_VALAC_OPTIONS} --define=GTK_3_22)
  message ("-- Compiling for Gtk 3.22")
else (GTK_3_22_FOUND)
  message ("-- Compiling for Gtk 3.18")
endif (GTK_3_22_FOUND)

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
  Widgets/EntryCombo.vala
  Widgets/Headerbar.vala
  Widgets/SlideList.vala
  Widgets/DynamicToolbar.vala
  Widgets/Welcome.vala
  Widgets/SlideWidget.vala
  Widgets/PresenterView.vala

  Widgets/ColorPicker/ColorButton.vala
  Widgets/ColorPicker/ColorPicker.vala
  Widgets/ColorPicker/Gradient.vala
  Widgets/ColorPicker/GradientEditor.vala
  Widgets/ColorPicker/PickerWindow.vala

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

# pbuilder is the Houston Builder
if ($ENV{USER} STREQUAL "pbuilder" OR $ENV{USER} STREQUAL "buildd")
    message ("-- Running in a server: Skipping tests")
else ($ENV{USER} STREQUAL "pbuilder" OR $ENV{USER} STREQUAL "buildd")
    add_subdirectory (Tests)
    message ("-- Adding tests for $ENV{USER}")
endif ($ENV{USER} STREQUAL "pbuilder" OR $ENV{USER} STREQUAL "buildd")
