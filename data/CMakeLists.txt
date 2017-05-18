# install desktop file
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.desktop
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/applications/)

# install assets
file(GLOB ASSETS_FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets)
install(DIRECTORY ${ASSETS_FILES}
        DESTINATION ${PKGDATADIR})

# install the appdata
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.appdata.xml
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/metainfo/)

# install the mimefile
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.mime.xml
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/mime/packages/)
