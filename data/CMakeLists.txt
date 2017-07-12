# install desktop file
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.desktop
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/applications/)

# install assets
file(GLOB ASSETS_FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets)
install(DIRECTORY ${ASSETS_FILES}
        DESTINATION ${PKGDATADIR})

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/scalable/apps/)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/scalable/mimetypes/
        RENAME application-x-spiceup.svg)

# install the appdata
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.appdata.xml
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/metainfo/)

# install the mimefile
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.mime.xml
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/mime/packages/)

# install thumbnailer file
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.thumbnailer
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/thumbnailers/)
