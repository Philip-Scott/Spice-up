configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.vala.cmake ${CMAKE_CURRENT_BINARY_DIR}/config.vala)

include(ValaPrecompile)

vala_precompile(VALA_C
  Main.vala
  Application.vala
  Window.vala
  Services/Settings.vala
  Services/Slide.vala
  Services/SlideManager.vala
  Services/FileManager.vala
  Services/HistoryManager.vala
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
  #${CMAKE_CURRENT_BINARY_DIR}/config.vala
  
  # LibGamepad
  Services/libgamepad/libgamepad.vala
  Services/libgamepad/gamepad-monitor.vala
  Services/libgamepad/gamepad.vala
  Services/libgamepad/helpers.vala
  Services/libgamepad/input-type.vala
  Services/libgamepad/mapping-error.vala
  Services/libgamepad/mapping-helpers.vala
  Services/libgamepad/mappings-manager.vala
  Services/libgamepad/mapping.vala
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

add_executable(spice-up ${VALA_C})

install(TARGETS spice-up RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})
