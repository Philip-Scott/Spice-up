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
using Cairo;

public class Spice.SlideList : Gtk.ScrolledWindow {
    private Gtk.Grid slides_grid;
    private SlideManager manager;

    private Gtk.Button new_slide_button;

    public SlideList (SlideManager manager) {
        this.manager = manager;

        get_style_context ().add_class ("slide-list");
        hscrollbar_policy = Gtk.PolicyType.NEVER;
        vexpand = true;

        slides_grid = new Gtk.Grid ();
        slides_grid.get_style_context ().add_class ("linked");
        slides_grid.orientation = Gtk.Orientation.VERTICAL;
        this.add (slides_grid);

        manager.new_slide_created.connect ((slide) => {
            add_slide (slide);
        });

        new_slide_button = add_new_slide ();

        new_slide_button.clicked.connect (() => {
            manager.new_slide ();
        });

        foreach (var slide in manager.slides) {
            var button = add_slide (slide);
        }
    }

    public Gtk.Button add_slide (Slide slide) {
        var button = new Gtk.Button ();
        var image = new Gtk.Image ();

        button.clicked.connect (() => {
            manager.current_slide = slide;
            set_preview (image, slide);
        });

        set_preview (image, slide);
        button.get_style_context ().add_class ("slide");
        button.add (image);

        slides_grid.remove (new_slide_button);
        slides_grid.add (button);
        slides_grid.add (new_slide_button);
        slides_grid.show_all ();

        return button;
    }

    public void set_preview (Gtk.Image image, Slide slide) {
        var buffer = new  Granite.Drawing.BufferSurface (slide.canvas.current_allocated_width, slide.canvas.current_allocated_height);
        slide.canvas.draw (buffer.context);

        image.set_from_pixbuf (buffer.load_to_pixbuf ().scale_simple (width, height, Gdk.InterpType.BILINEAR ));
    }

    int width = 200;
    int height = 150;

    public Gtk.Button add_new_slide () {
        var button = new Gtk.Button ();
        var plus_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.DIALOG);
        plus_icon.margin = 24;

        button.get_style_context ().add_class ("slide");
        button.get_style_context ().add_class ("new");
        button.add (plus_icon);
        button.margin = 12;

        slides_grid.add (button);
        slides_grid.show_all ();

        return button;
    }
}


