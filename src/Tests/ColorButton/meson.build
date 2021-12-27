color_button_test_exec = executable(
    'ColorButtonTests',
    'ColorButtonTest.vala',
    'TestCommon.vala',

    meson.source_root() / 'src' / 'Widgets' / 'ColorPicker' / 'ColorButton.vala',
    meson.source_root() / 'src' / 'Widgets' / 'ColorPicker' / 'ColorChooser.vala',
    meson.source_root() / 'src' / 'Widgets' / 'ColorPicker' / 'Gradient.vala',
    meson.source_root() / 'src' / 'Widgets' / 'ColorPicker' / 'GradientEditor.vala',
    meson.source_root() / 'src' / 'Widgets' / 'ColorPicker' / 'PickerWindow.vala',

    dependencies : deps,
    install: false
)

test ('ColorButtonTests', color_button_test_exec)
