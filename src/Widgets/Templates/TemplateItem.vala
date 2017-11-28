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

public class Spice.Widgets.Templates.TemplateItem : Gtk.FlowBoxChild {
    public File file { get; construct set; }
    public string data { get; private set; }

    private Spice.SlideWidget image;
    private Gtk.Popover? popover = null;

    private string last_aspect_ratio;

    public TemplateItem (File file) {
        this.file = file;

        set_tooltip_text (_("Create new presentation"));
        halign = Gtk.Align.CENTER;

        image = new Spice.SlideWidget ();
        image.show_button = false;

        add (image);

        get_thumbnail ();
        show_all ();
    }

    private void get_thumbnail () {
        if (file.query_exists ()) {
            new Thread<void*> ("content-loading", () => {
                var dis = new DataInputStream (file.read ());
                size_t size;

                data = dis.read_upto ("\0", -1, out size);

                var pixbuf = Utils.base64_to_pixbuf (Utils.get_thumbnail_data (data));

                Idle.add (() => {
                    image.pixbuf = pixbuf;
                    return GLib.Source.REMOVE;
                });

                return null;
            });
        } else {
            warning ("File doesn't exist");
        }
    }
}
