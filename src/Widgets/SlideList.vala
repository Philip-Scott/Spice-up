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

        var slide = new Gtk.Button ();
        var plus_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.DIALOG);
        slide.can_focus = false;
        plus_icon.margin = 24;
        slide.margin = 12;
        slide.get_style_context ().add_class ("slide");
        slide.get_style_context ().add_class ("new");
        slide.add (plus_icon);

        slides_grid.add (slide);

        this.add (slides_grid);
    }
}


