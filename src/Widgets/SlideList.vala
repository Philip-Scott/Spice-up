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
        this.add (slides_grid);

        slides_list.row_selected.connect ((row) => {
            if (row is SlideListRow) {
                var slide = (SlideListRow) row;
                manager.current_slide = slide.slide;
            }
        });

        manager.new_slide_created.connect ((slide) => {
            add_slide (slide);
        });

        manager.slides_sorted.connect (() => {
            slides_list.invalidate_sort ();
        });

        manager.current_slide_changed.connect ((selected) => {
            foreach (var row in slides_list.get_children ()) {
                if (row is SlideListRow) {
                    var preview = (SlideListRow) row;
                    if (preview.slide == selected) {
                        slides_list.select_row (preview);
                        break;
                    }
                }
            }
        });

        manager.reseted.connect (() => {
            foreach (var row in slides_list.get_children ()) {
                row.destroy ();
            }
        });

        slides_list.set_sort_func ((row1, row2) => {
            var slide1 = manager.slides.index_of (((SlideListRow) row1).slide);
            var slide2 = manager.slides.index_of (((SlideListRow) row2).slide);

            if (slide1 < slide2) return -1;
            else if (slide2 < slide1) return 1;
            else return 0;
        });

        new_slide_button = add_new_slide ();
        slides_grid.add (new_slide_button);

        new_slide_button.clicked.connect (() => {
            var slide = manager.new_slide (null, true);

            manager.making_new_slide = true;
            manager.current_slide = slide;
            manager.making_new_slide = false;
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

    public static int WIDTH = 200;
    public static int HEIGHT = 150;

    public Gtk.Button add_new_slide () {
        var button = new Gtk.Button ();
        var plus_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.DIALOG);
        plus_icon.margin = 24;

        button.get_style_context ().add_class ("slide");
        button.get_style_context ().add_class ("new");
        button.add (plus_icon);
        button.set_size_request (WIDTH, HEIGHT);
        button.margin = 9;

        return button;
    }

    private class SlideListRow : Gtk.ListBoxRow {
        public unowned Spice.Slide slide;

        public SlideListRow (Slide slide) {
            this.slide = slide;
            var image = slide.preview;

            this.add (image);

            image.get_style_context ().add_class ("view");
            image.get_style_context ().add_class ("canvas");
            image.get_style_context ().add_class ("preview");
            image.margin = 9;

            set_size_request (SlideList.WIDTH - 24, SlideList.HEIGHT - 24);

            slide.visible_changed.connect ((val) => {
                this.visible = val;
                this.no_show_all = !val;

                this.show_all ();
            });
        }
    }
}
