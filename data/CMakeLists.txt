# install desktop file
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.desktop
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/applications/)

# install assets
file(GLOB ASSETS_FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets)
install(DIRECTORY ${ASSETS_FILES}
        DESTINATION ${PKGDATADIR})

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/symbolic/spiceup-shape-symbolic.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/symbolic/apps/)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/symbolic/spiceup-text-symbolic.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/symbolic/apps/)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/scalable/apps/)

# install the appdata
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.appdata.xml
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/appdata/)
