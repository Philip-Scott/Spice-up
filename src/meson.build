config_data = configuration_data()
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

vala_files = [
    'Application.vala',
    'Main.vala',
    'Window.vala',

    'Services' / 'Clipboard.vala',
    'Services' / 'Settings.vala',
    'Services' / 'Slide.vala',
    'Services' / 'SlideManager.vala',
    'Services' / 'FileManager.vala',
    'Services' / 'HistoryManager.vala',
    'Services' / 'ImageHandler.vala',
    'Services' / 'Utils.vala',
    'Services' / 'GamepadSlideController.vala',

    'Widgets' / 'Canvas.vala',
    'Widgets' / 'EntryCombo.vala',
    'Widgets' / 'Headerbar.vala',
    'Widgets' / 'SlideList.vala',
    'Widgets' / 'DynamicToolbar.vala',
    'Widgets' / 'Welcome.vala',
    'Widgets' / 'SlideWidget.vala',
    'Widgets' / 'PresenterView.vala',
    'Widgets' / 'PresenterNotes.vala',

    'Widgets' / 'ColorPicker' / 'ColorButton.vala',
    'Widgets' / 'ColorPicker' / 'ColorChooser.vala',
    'Widgets' / 'ColorPicker' / 'Gradient.vala',
    'Widgets' / 'ColorPicker' / 'GradientEditor.vala',
    'Widgets' / 'ColorPicker' / 'PickerWindow.vala',

    'Widgets' / 'CanvasItems' / 'CanvasItem.vala',
    'Widgets' / 'CanvasItems' / 'TextItem.vala',
    'Widgets' / 'CanvasItems' / 'ColorItem.vala',
    'Widgets' / 'CanvasItems' / 'ImageItem.vala',
    'Widgets' / 'CanvasItems' / 'Grabber.vala',

    'Widgets' / 'Toolbars' / 'CanvasBar.vala',
    'Widgets' / 'Toolbars' / 'CommonBar.vala',
    'Widgets' / 'Toolbars' / 'ImageBar.vala',
    'Widgets' / 'Toolbars' / 'ShapeBar.vala',
    'Widgets' / 'Toolbars' / 'TextBar.vala',
    'Widgets' / 'Toolbars' / 'Toolbar.vala',

    'Widgets' / 'Library' / 'LibraryItem.vala',
    'Widgets' / 'Library' / 'Library.vala',

    # LibGamepad
    'Services' / 'libgamepad' / 'libgamepad.vala',
    'Services' / 'libgamepad' / 'gamepad-monitor.vala',
    'Services' / 'libgamepad' / 'gamepad.vala',
    'Services' / 'libgamepad' / 'helpers.vala',
    'Services' / 'libgamepad' / 'input-type.vala',
    'Services' / 'libgamepad' / 'raw-gamepad-interface.vala',
    'Services' / 'libgamepad' / 'raw-gamepad-monitor-interface.vala',
    'Services' / 'libgamepad' / 'standard-gamepad-axis.vala',
    'Services' / 'libgamepad' / 'standard-gamepad-button.vala',

    'Services' / 'libgamepad' / 'drivers' / 'linux' / 'guid-helpers.vala',
    'Services' / 'libgamepad' / 'drivers' / 'linux' / 'raw-gamepad.vala',
    'Services' / 'libgamepad' / 'drivers' / 'linux' / 'raw-gamepad-monitor.vala',

    # Granite Staging
    'GraniteStaging' / 'Inhibitor.vala'
]

deps = [
    evdev_dep,
    gee_dep,
    glib_dep,
    gobject_dep,
    granite_dep,
    gtk_dep,
    gudev_dep,
    json_glib_dep,
    soup_dep,
]

executable(
    meson.project_name(),
    config_file,
    gresource,
    vala_files,
    dependencies: deps,
    install: true
)

subdir('Tests')
