set (TEST_NAME color-item )

vala_precompile (VALA_TEST_C
  ColorItemTest.vala
  TestCommon.vala
  MockedCanvasItem.vala
  ../../Widgets/CanvasItems/ColorItem.vala
  PACKAGES
  ${VALA_DEPS}
  OPTIONS
    --thread
    --target-glib=2.32 # Needed for new thread API
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

add_executable (${TEST_NAME} ${VALA_TEST_C})
add_test (core-${TEST_NAME} ${TEST_NAME})

