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

public class Spice.Widgets.Library.LibraryItem : Gtk.FlowBoxChild {
    public File file { get; construct set; }

    private Gtk.Image image;

    public LibraryItem (File file) {
        this.file = file;

        set_tooltip_text (_("Open: %s".printf (file.get_path ())));
        halign = Gtk.Align.START;

        image = new Gtk.Image ();
        image.margin = 12;

        image.get_style_context ().add_class ("card");

        add (image);

        get_thumbnail ();
        show_all ();
    }

    private void get_thumbnail () {
        if (file.query_exists ()) {
            string data;
            FileUtils.get_contents (file.get_path (), out data);

            var pixbuf = Utils.base64_to_pixbuf (Utils.get_thumbnail_data (data));
            image.set_from_pixbuf (pixbuf);
        }
    }
}
