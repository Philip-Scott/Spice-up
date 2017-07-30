# install desktop file
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.desktop
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/applications/)

# install assets
file(GLOB ASSETS_FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets)
install(DIRECTORY ${ASSETS_FILES}
        DESTINATION ${PKGDATADIR})

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/16/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/16x16/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/24/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/24x24/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/32/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/32x32/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/48/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/48x48/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/64/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/64x64/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/128/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/128x128/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/128/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/scalable/apps/)

#MIME
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/16/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/16x16/mimetypes/
        RENAME application-x-spiceup.svg)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/24/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/24x24/mimetypes/
        RENAME application-x-spiceup.svg)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/32/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/32x32/mimetypes/
        RENAME application-x-spiceup.svg)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/48/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/48x48/mimetypes/
        RENAME application-x-spiceup.svg)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/64/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/64x64/mimetypes/
        RENAME application-x-spiceup.svg)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/128/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/128x128/mimetypes/
        RENAME application-x-spiceup.svg)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/128/com.github.philip-scott.spice-up.svg
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/icons/hicolor/scalable/mimetypes/
        RENAME application-x-spiceup.svg)

# install the appdata
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.appdata.xml
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/metainfo/)

# install the mimefile
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.philip-scott.spice-up.mime.xml
        DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/mime/packages/)
