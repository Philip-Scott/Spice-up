text_item_test_exec = executable(
    'TextItemTests',
    'TextItemTest.vala',
    'MockedCanvasItem.vala',
    'TestCommon.vala',

    meson.source_root() / 'src' / 'Widgets' / 'CanvasItems' / 'TextItem.vala',

    dependencies : deps,
    install: false
)

test ('TextItemTests', text_item_test_exec)
