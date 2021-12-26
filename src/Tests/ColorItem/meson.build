color_item_test_exec = executable(
    'ColorItemTests',
    'ColorItemTest.vala',
    'MockedCanvasItem.vala',
    'TestCommon.vala',

    meson.source_root() / 'src' / 'Widgets' / 'CanvasItems' / 'ColorItem.vala',

    dependencies : deps,
    install: false
)

test ('ColorItemTests', color_item_test_exec)
