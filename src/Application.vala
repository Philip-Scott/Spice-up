/*
* Copyright (c) 2016 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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
    public Spice.Window window;
    public string DATA_DIR;
}

public class Spice.Application : Granite.Application {
    public const string PROGRAM_NAME = N_("Spice-Up");
    public const string COMMENT = N_("");
    public const string ABOUT_STOCK = N_("About Spice-Up");

    public bool running = false;

    construct {
        flags |= ApplicationFlags.HANDLES_OPEN;

        application_id = "com.github.philip-scott.spice-up";
        program_name = PROGRAM_NAME;
        app_years = "2016-2017";
        exec_name = "spice-up";
        app_launcher = "com.github.philip-scott.spice-up";

        build_version = "0.8";
        app_icon = "com.github.philip-scott.spice-up";
        main_url = "https://github.com/Philip-Scott/Spice-up/";
        bug_url = "https://github.com/Philip-Scott/Spice-up/issues";
        help_url = "https://github.com/Philip-Scott/Spice-up/";
        translate_url = "https://github.com/Philip-Scott/Spice-up/tree/master/po";
        about_authors = {"Felipe Escoto <felescoto95@hotmail.com>", null};
        about_translators = _("translator-credits");

        about_license_type = Gtk.License.GPL_3_0;
    }

    public override void open (File[] files, string hint) {
        string[] uris = {};
        foreach (var file in files) {
            uris += file.get_uri ();
        }

        activate ();
        if (window != null) {
            window.open_file (File.new_for_uri (uris[0]));
        }
    }

    public override void activate () {
        if (!running) {
            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/com/github/philip-scott/spice-up");

            settings = Spice.Services.Settings.get_instance ();
            window = new Spice.Window (this);
            this.add_window (window);

            running = true;
        }

        window.show_app ();
    }
}
