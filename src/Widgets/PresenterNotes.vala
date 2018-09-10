/*
* Copyright (c) 2018 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

public class Spice.PresenterNotes : Gtk.Revealer {
    public signal void text_changed (string text);

    public Gtk.TextView notes_area { get; construct set; }

    private bool setting_text = false;

    construct {
        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;

        notes_area = new Gtk.TextView ();
        notes_area.set_wrap_mode (Gtk.WrapMode.WORD);
        notes_area.left_margin = 6;
        notes_area.get_style_context ().add_class ("h3");
        notes_area.get_style_context ().add_class ("h4");

        notes_area.buffer.changed.connect (() => {
            if (!setting_text) {
                text_changed (notes_area.buffer.text);
            }
        });

        var notes_scrolled = new Gtk.ScrolledWindow (null, null);
        notes_scrolled.min_content_height = 150;
        notes_scrolled.hexpand = true;
        notes_scrolled.add (notes_area);

        grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        grid.add (notes_scrolled);

        add (grid);
        show_all ();
    }

    public void set_text (string text) {
        setting_text = true;
        notes_area.buffer.text = text;
        setting_text = false;
    }
}