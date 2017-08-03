enable_testing (true)

# Color Item Test
set (TEST_NAME text-item )

vala_precompile (VALA_TEST_C
  TextItemTest.vala
  TestCommon.vala
  MockedCanvasItem.vala
  ../../Widgets/CanvasItems/TextItem.vala
  PACKAGES
  ${VALA_DEPS}
  OPTIONS
    --thread
    --target-glib=2.32 # Needed for new thread API
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

add_executable (${TEST_NAME} ${VALA_TEST_C})
add_test (core-${TEST_NAME} ${TEST_NAME})
