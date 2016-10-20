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

public class Spice.Application : Gtk.Application {
    public const string PROGRAM_NAME = N_("Presentations");
    public const string COMMENT = N_("");
    public const string ABOUT_STOCK = N_("About Spice-up");

    public bool running = false;

    public Application () {
        Object (application_id: "com.github.philip-scott.spice-up");
    }

    public override void activate () {
        if (!running) {
            settings = Spice.Services.Settings.get_instance ();
            window = new Spice.Window (this);
            this.add_window (window);

            running = true;
        }

        window.show_app ();
    }
}
