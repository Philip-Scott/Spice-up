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
    private Gtk.ListBox slides_list;
    private SlideManager manager;

    private Gtk.Button new_slide_button;

    public SlideList (SlideManager manager) {
        this.manager = manager;

        hscrollbar_policy = Gtk.PolicyType.NEVER;
        vexpand = true;

        slides_grid = new Gtk.Grid ();
        slides_grid.orientation = Gtk.Orientation.VERTICAL;
        slides_grid.get_style_context ().add_class ("slide-list");

        slides_list = new Gtk.ListBox ();
        slides_list.get_style_context ().add_class ("slide-list");
        slides_list.get_style_context ().add_class ("linked");

        slides_grid.add (slides_list);
        slides_grid.add (add_new_slide ());
        this.add (slides_grid);

        slides_list.row_selected.connect ((row) => {
            if (row is SlideListRow) {
                var slide = (SlideListRow) row;
                manager.current_slide.reload_preview_data ();

                manager.current_slide = slide.slide;
            }
        });

        manager.new_slide_created.connect ((slide) => {
            add_slide (slide);
        });

        new_slide_button = add_new_slide ();

        new_slide_button.clicked.connect (() => {
            manager.new_slide ();
        });

        foreach (var slide in manager.slides) {
            add_slide (slide);
        }
    }

    private SlideListRow add_slide (Slide slide) {
        var slide_row = new SlideListRow (slide);

        slide_row.get_style_context ().add_class ("slide");

        slides_list.add (slide_row);
        slides_list.show_all ();

        return slide_row;
    }

    public void set_preview (Gtk.Image image, Slide slide) {
        var buffer = new  Granite.Drawing.BufferSurface (slide.canvas.current_allocated_width, slide.canvas.current_allocated_height);
        slide.canvas.draw (buffer.context);
        image.set_from_file ("/home/felipe/2.png");
        image.set_from_pixbuf (buffer.load_to_pixbuf ().scale_simple (width, height, Gdk.InterpType.BILINEAR ));
    }

    public static int width = 200;
    public static int height = 154;

    public Gtk.Button add_new_slide () {
        var button = new Gtk.Button ();
        var plus_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.DIALOG);
        plus_icon.margin = 24;

        button.get_style_context ().add_class ("slide");
        button.get_style_context ().add_class ("new");
        button.add (plus_icon);
        button.set_size_request (width - 24, height - 24);
        button.margin = 6;

        return button;
    }

    private class SlideListRow : Gtk.ListBoxRow {
        public Spice.Slide slide;

        public SlideListRow (Slide slide) {
            this.slide = slide;
            this.add (slide.preview);

            margin = 6;
            margin_top = 3;
            margin_bottom = 3;
        }
    }
}
