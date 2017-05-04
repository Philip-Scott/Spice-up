vala_sources = [
    'libgamepad.vala',
    'gamepad-monitor.vala',
    'gamepad.vala',
    'helpers.vala',
    'input-type.vala',
    'mapping-error.vala',
    'mapping-helpers.vala',
    'mappings-manager.vala',
    'mapping.vala',
    'raw-gamepad-interface.vala',
    'raw-gamepad-monitor-interface.vala',
    'standard-gamepad-axis.vala',
    'standard-gamepad-button.vala',
]

vala_args = [
    '--library=libgamepad-1.0',
    '--shared-library=libgamepad',
    '--gir=libgamepad-1.0.gir',
]

if get_option('enable_docs')
    vala_args += '--vapi-comments' # preserve the documentation comments for valadoc
endif

vala_deps = [glib, gobject, gio]

# Drivers

if host_machine.system() == 'linux'
    vala_sources += [
        'drivers/linux/guid-helpers.vala',
        'drivers/linux/raw-gamepad.vala',
        'drivers/linux/raw-gamepad-monitor.vala',
    ]

    vala_args += [
        '--define=PLATFORM_LINUX',
        '--pkg=posix',
        '--pkg=linux',
        '--vapidir=' + meson.current_source_dir() + '/drivers/linux/vapis/'
    ]

    gudev = dependency('gudev-1.0')
    libevdev = dependency('libevdev')
    vala_deps += [gudev, libevdev]
else
    error ('Sorry. Currently not supported on your platform : ' + host_machine.system())
endif

# Main library

libgamepad_lib = shared_library('gamepad',
                                vala_sources,
                                resources,
                                vala_args: vala_args,
                                install: true,
                                dependencies : vala_deps)

libgamepad = declare_dependency(link_with: libgamepad_lib,
                                include_directories: include_directories('.'))


install_data('libgamepad.deps', install_dir: 'share/vala/vapi')

pkg_mod = import('pkgconfig')
pkg_mod.generate(requires: 'gio-2.0',
                 libraries : libgamepad_lib,
                 version : meson.project_version(),
                 name : 'LibGamepad',
                 filebase : 'libgamepad',
                 description : 'A simple library to handle gamepads.')
