icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        'icons' / i / meson.project_name() + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i / 'apps'
    )
    install_data(
        'icons' / i / meson.project_name() + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i + '@2' / 'apps'
    )
endforeach

install_data(
    meson.project_name() + '.desktop',
    install_dir: get_option('datadir') / 'applications'
)

install_data(
    meson.project_name() + '.appdata.xml',
    install_dir: get_option('datadir') / 'metainfo',
)

install_data(
    meson.project_name() + '.mime.xml',
    install_dir: get_option('datadir') / 'mime' / 'packages',
)
