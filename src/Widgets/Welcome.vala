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

public class Spice.Welcome : Granite.Widgets.Welcome {
    public signal void open_file (File file);

    public Welcome () {
        base ("Spice up", _("Make a Simple Presentation"));
        append ("document-new", _("New Presentation"), _("Create a new presentation"));
        append ("folder-open", _("Open File"), _("Open a saved presentation"));

        if (settings.last_file != "") {
            var file = File.new_for_path (settings.last_file);
            append ("x-office-presentation", _("Open Last File"), file.get_basename ());
        }

        this.activated.connect ((index) => {
            switch (index) {
                case 0:
                    var file = Spice.Services.FileManager.save_presentation ();
                    if (file != null) open_file (file);
                    break;
                case 1:
                    var file = Spice.Services.FileManager.open_presentation ();
                    if (file != null) open_file (file);
                    break;

                case 2:
                    open_file (File.new_for_path (settings.last_file));
                    break;
             }
        });
    }
}
