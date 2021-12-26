project(
    'com.github.philip-scott.spice-up',
    'vala', 'c',
    version: '0.7'
)

gnome = import('gnome')
i18n = import('i18n')

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')
add_project_arguments(
    [
        '--define=PLATFORM_LINUX',
        '--pkg=linux',
        '--vapidir', meson.current_source_dir() / 'vapi'
    ],
    language: 'vala'
)

gresource = gnome.compile_resources(
    'gresource',
    'data' / 'assets.gresource.xml',
    source_dir: 'data'
)

evdev_dep = dependency('libevdev')
gee_dep = dependency('gee-0.8')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
granite_dep = dependency('granite', version: '>=0.5')
gtk_dep = dependency('gtk+-3.0')
gudev_dep = dependency('gudev-1.0')
json_glib_dep = dependency('json-glib-1.0')
soup_dep = dependency('libsoup-2.4')

subdir('data')
subdir('src')
