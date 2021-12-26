image_item_test_exec = executable(
    'ImageItemTests',
    'ImageItemTest.vala',
    'MockedCanvasItem.vala',
    'TestCommon.vala',

    meson.source_root() / 'src' / 'Widgets' / 'CanvasItems' / 'ImageItem.vala',

    dependencies : deps,
    install: false
)

test ('ImageItemTests', image_item_test_exec)
