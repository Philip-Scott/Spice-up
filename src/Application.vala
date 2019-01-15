/*
* Copyright (c) 2017 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
* Authored by: Felipe Escoto <felescoto95@hotmail.com>
*/

namespace Spice {
    public Spice.Services.Settings settings;
    public string DATA_DIR;
}

public class Spice.Application : Granite.Application {
    public const string PROGRAM_NAME = N_("Spice-Up");
    public const string ABOUT_STOCK = N_("About Spice-Up");
    public const string APP_ID = "com.github.philip-scott.spice-up";
    public const string RESOURCE_PATH = "/com/github/philip-scott/spice-up/";

    public bool running = false;

    public static Spice.Application _instance = null;
    public static unowned Spice.Application instance {
        get {
            if (_instance == null) {
                _instance = new Spice.Application ();
            }
            return _instance;
        }
    }

    private Gee.HashMap<string, Spice.Window> opened_files;

    construct {
        flags |= ApplicationFlags.HANDLES_OPEN;

        application_id = APP_ID;
        program_name = PROGRAM_NAME;
        exec_name = APP_ID;
        app_launcher = APP_ID;

        build_version = "1.7";

        opened_files = new Gee.HashMap<string, Spice.Window>();
        settings = Spice.Services.Settings.get_instance ();
        Granite.Staging.Services.Inhibitor.initialize (this);
    }

    public override void open (File[] files, string hint) {
        init ();
        foreach (var file in files) {
            if (is_file_opened (file)) {
                // Preset active window with file
                var window = get_window_from_file (file);
                window.show_app ();
            } else {
                // Open New window
                var window = new Spice.Window (this);
                this.add_window (window);

                window.open_file (file);
                window.show_app ();
            }
        }
    }

    private void init () {
        if (!running) {
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path (RESOURCE_PATH);
            running = true;
        }
    }

    public override void activate () {
        init ();

        var window = new Spice.Window (this);
        this.add_window (window);
        window.show_welcome ();

        get_active_spice_window ().show_app ();
    }

    public static unowned Spice.Window get_active_spice_window () {
        return (Spice.Window) instance.get_active_window ();
    }

    public bool is_file_opened (File file) {
        return opened_files.has_key (file.get_uri ());
    }

    public void unregister_file_from_window (File file) {
        if (is_file_opened (file)) {
            opened_files.unset (file.get_uri ());
        }
    }

    public void register_file_to_window (File file, Spice.Window window) {
        if (!is_file_opened (file)) {
            opened_files.set (file.get_uri (), window);
        } else {
            warning ("File was opened in two separate windows");
        }
    }

    public Spice.Window get_window_from_file (File file) {
        return opened_files.get (file.get_uri ());
    }
}
