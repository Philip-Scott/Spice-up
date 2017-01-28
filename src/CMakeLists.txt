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
PACKAGES
  ${VALA_DEPS}
OPTIONS
  ${GLOBAL_VALAC_OPTIONS}
  -g
  --thread
  --target-glib=2.38 # FIXME check before, and target the same version
)

add_executable(spice-up ${VALA_C})

install(TARGETS spice-up RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})
