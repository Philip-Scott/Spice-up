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

public class Spice.SlideList : Gtk.Grid {
    public static int WIDTH = 200;
    public static int HEIGHT = 150;

    private Gtk.ListBox slides_list;
    private unowned SlideManager manager;

    public SlideList (SlideManager manager) {
        orientation = Gtk.Orientation.VERTICAL;
        get_style_context ().add_class ("slide-list");

        this.manager = manager;

        var scrollbox = new Gtk.ScrolledWindow (null, null);
        scrollbox.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrollbox.vexpand = true;

        slides_list = new Gtk.ListBox ();
        slides_list.get_style_context ().add_class ("linked");
        slides_list.get_style_context ().add_class ("slide-list");
        slides_list.vexpand = true;

        scrollbox.add (slides_list);
        add (scrollbox);

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

        add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var plus_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        plus_icon.margin = 3;

        var new_slide_button = new Gtk.Button ();

        new_slide_button.set_tooltip_text (_("Add a Slide"));
        new_slide_button.get_style_context ().add_class ("new");
        new_slide_button.add (plus_icon);
        new_slide_button.set_size_request (WIDTH, 0);
        new_slide_button.margin = 0;
        new_slide_button.can_focus = false;

        new_slide_button.clicked.connect (() => {
            Utils.new_slide (manager);
        });


        add (new_slide_button);

        foreach (var slide in manager.slides) {
            add_slide (slide);
        }
    }

    private SlideListRow add_slide (Slide slide) {
        var slide_row = new SlideListRow (slide, manager);

        slide_row.get_style_context ().add_class ("slide");

        slides_list.add (slide_row);
        slides_list.show_all ();

        return slide_row;
    }

    private class SlideListRow : Gtk.ListBoxRow {
        public unowned Spice.Slide slide;
        private unowned SlideManager manager;

        private SlideWidget slide_widget;

        public SlideListRow (Slide slide, SlideManager manager) {
            this.slide = slide;
            this.manager = manager;

            slide_widget = new SlideWidget.from_slide (slide);

            slide_widget.settings_requested.connect (() => {
                show_rightclick_menu ();
            });

            add (slide_widget);

            set_size_request (SlideList.WIDTH - 24, SlideList.HEIGHT - 24);

            slide.visible_changed.connect ((val) => {
                this.visible = val;
                this.no_show_all = !val;

                this.show_all ();
            });

            style ();
        }

        public void style () {
            Utils.set_style (this, STYLE_CSS);
        }

        private const string STYLE_CSS = """
            .list-row:active {
                opacity: 0.90;
            }
        """;

        public void show_rightclick_menu () {
            var menu = new Gtk.Menu ();

            var cut = new Gtk.MenuItem.with_label (_("Cut"));
            var copy = new Gtk.MenuItem.with_label (_("Copy"));
            var paste = new Gtk.MenuItem.with_label (_("Paste"));
            var delete_slide = new Gtk.MenuItem.with_label (_("Delete"));

            var new_slide = new Gtk.MenuItem.with_label (_("New Slide"));
            // var new_item = new Gtk.MenuItem.with_label (_("Skip Slide"));
            var duplicate_slide = new Gtk.MenuItem.with_label (_("Duplicate Slide"));
            var set_as_preview = new Gtk.MenuItem.with_label (_("Set as File Preview"));

            cut.activate.connect (() => {
                Clipboard.cut (this.slide);
            });

            copy.activate.connect (() => {
                Clipboard.copy (this.slide);
            });

            paste.activate.connect (() => {
                Clipboard.paste (this.manager);
            });

            delete_slide.activate.connect (() => {
                Clipboard.delete (this.slide);
            });

            new_slide.activate.connect (() => {
                Utils.new_slide (manager);
            });

            duplicate_slide.activate.connect (() => {
                Clipboard.duplicate (this.slide, this.manager);
            });

            set_as_preview.activate.connect (() => {
                this.manager.preview_slide = this.slide;
            });

            menu.add (cut);
            menu.add (copy);
            menu.add (paste);
            menu.add (delete_slide);
            menu.add (new Gtk.SeparatorMenuItem ());
            menu.add (new_slide);
            menu.add (duplicate_slide);
            menu.add (new Gtk.SeparatorMenuItem ());
            menu.add (set_as_preview);

            menu.attach_to_widget (this, null);
            menu.show_all ();

            menu.selection_done.connect (() => {
                menu.detach ();
                menu.destroy ();
            });

            menu.popup_at_widget (this, Gdk.Gravity.CENTER, Gdk.Gravity.CENTER, null);
        }

        public override bool button_press_event (Gdk.EventButton event) {
            activate ();

            if (event.button == 3) {
                show_rightclick_menu ();
            }

            return false;
        }
    }
}
