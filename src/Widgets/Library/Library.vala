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

public class Spice.Widgets.Library.Library : Gtk.ScrolledWindow {
    public signal void item_selected (File file);

    private Gtk.FlowBox item_box;

    public Library (string[] files) {
        hscrollbar_policy = Gtk.PolicyType.NEVER;

        item_box = new Gtk.FlowBox ();

        item_box.valign = Gtk.Align.START;
        item_box.min_children_per_line = 2;
        item_box.max_children_per_line = 2;;
        item_box.margin = 12;
        item_box.expand = false;

        add (item_box);

        item_box.child_activated.connect ((child) => {
            item_selected ((child as LibraryItem).file);
        });

        var existing_files = new Array<string> ();
        foreach (var path in files) {
            var file = File.new_for_path (path);
            if (file.query_exists ()) {
                add_file (file);
                existing_files.append_val (path);
            }
        }

        settings.last_files = existing_files.data;
    }

    public void add_file (File file) {
        if (!file.query_exists ()) return;

        var item = new LibraryItem (file);
        item_box.add (item);
    }
}
