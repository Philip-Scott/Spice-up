canvas_test_exec = executable(
    'CanvasTests',
    'CanvasTest.vala',
    'TestCommon.vala',

    meson.source_root() / 'src' / 'Widgets' / 'CanvasItems' / 'Grabber.vala',
    meson.source_root() / 'src' / 'Widgets' / 'CanvasItems' / 'CanvasItem.vala',
    meson.source_root() / 'src' / 'Widgets' / 'Canvas.vala',

    dependencies : deps,
    install: false
)

test ('CanvasTests', canvas_test_exec)
