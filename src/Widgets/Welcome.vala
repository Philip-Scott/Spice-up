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

public class Spice.Welcome : Gtk.Box {
    public signal void open_file (File file);

    private Granite.Widgets.Welcome welcome;
    private Spice.Widgets.Library.Library? library = null;
    private Gtk.Separator separator;

    public Welcome () {
        orientation = Gtk.Orientation.HORIZONTAL;
        get_style_context ().add_class ("view");

        width_request = 950;
        height_request = 500;

        welcome = new Granite.Widgets.Welcome ("Spice-Up", _("Make a Simple Presentation"));
        welcome.hexpand = true;

        welcome.append ("document-new", _("New Presentation"), _("Create a new presentation"));
        welcome.append ("folder-open", _("Open File"), _("Open a saved presentation"));

        separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);

        add (welcome);
        add (separator);

        welcome.activated.connect ((index) => {
            switch (index) {
                case 0:
                    var file = Spice.Services.FileManager.new_presentation ();
                    if (file != null) open_file (file);
                    break;
                case 1:
                    var file = Spice.Services.FileManager.open_presentation ();
                    if (file != null) open_file (file);
                    break;
             }
        });
    }

    public void reload () {
        var files = settings.last_files;

        if (library != null) {
            remove (library);
            library.destroy ();
            library = null;
        }

        if (files.length > 0 ) {
            library = new Spice.Widgets.Library.Library (files);
            add (library);

            library.item_selected.connect ((file) => {
                open_file (file);
            });

            separator.visible = true;
            separator.no_show_all = false;

            this.show_all ();
        } else {
            separator.visible = false;
            separator.no_show_all = true;
        }
    }
}
