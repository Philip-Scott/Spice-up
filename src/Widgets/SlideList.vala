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

public class Spice.SlideList : Gtk.Box {
    private Gtk.Grid slides_grid;

    public SlideList () {
        get_style_context ().add_class ("slide-list");
        vexpand = true;

        slides_grid = new Gtk.Grid ();
        slides_grid.orientation = Gtk.Orientation.VERTICAL;

        add_slide (new Spice.Canvas.preview ());
        add_new_slide ();

        this.add (slides_grid);
    }

    public void add_slide (Gtk.Widget slide) {
        var button = new Gtk.Button ();
        button.get_style_context ().add_class ("slide");
        button.get_style_context ().add_class ("new");
        button.add (slide);
        button.margin = 12;

        slides_grid.add (button);
    }

    public void add_new_slide () {
        var plus_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.DIALOG);
        plus_icon.margin = 24;
        add_slide (plus_icon);
    }
}


