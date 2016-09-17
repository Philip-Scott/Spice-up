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

public class Spice.DynamicToolbar : Gtk.Box {
    private string TEXT = "text";
    private string IMAGE = "image";
    private string SHAPE = "shape";
    private string CANVAS = "canvas";

    private Gtk.Box text_bar;
    private Gtk.Box image_bar;
    private Gtk.Box shape_bar;

    private CanvasItem? item = null;
    private Gtk.Stack stack;

    //Text Toolbar
    private Gtk.FontButton font_button;
    private Gtk.ColorButton text_color_button;

    //ColorToolbar
    private Gtk.ColorButton background_color_button;


    public DynamicToolbar () {
        stack = new Gtk.Stack ();
        stack.set_transition_type (Gtk.StackTransitionType.OVER_DOWN);

        get_style_context ().add_class ("toolbar");
        get_style_context ().add_class ("inline-toolbar");

        build_textbar ();
        build_imagebar ();
        build_shapebar ();
        build_canvasbar ();

        this.add (stack);
    }

    public void item_selected (Spice.CanvasItem item) {
        stderr.printf ("Selecting Item\n");

        if (item is TextItem) {
            stack.set_visible_child_name (TEXT);
            font_button.font_name = ((TextItem) item).font;
        } else if (item is ColorItem) {
            stack.set_visible_child_name (SHAPE);

            Gdk.RGBA rgba = Gdk.RGBA ();
            rgba.parse (((ColorItem) item).background_color);

            background_color_button.rgba = rgba;
        }

        this.item = item;
    }

    private void build_textbar () {
        text_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        text_color_button = new Gtk.ColorButton ();

        text_color_button.color_set.connect (() => {
            ((TextItem) this.item).font_color = text_color_button.rgba.to_string ();
            this.item.style ();
        });

        font_button = new Gtk.FontButton ();

        font_button.show_size = false;

        font_button.font_set.connect (() => {
            ((TextItem) this.item).font = font_button.font;
            this.item.style ();
        });

        text_bar.add (font_button);
        text_bar.add (text_color_button);

        stack.add_named (text_bar, TEXT);
    }

    private void build_imagebar () {
        image_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        stack.add_named (image_bar, IMAGE);
    }

    private void build_shapebar () {
        shape_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        background_color_button = new Gtk.ColorButton ();
        background_color_button.use_alpha = true;

        background_color_button.color_set.connect (() => {
            ((ColorItem) this.item).background_color = background_color_button.rgba.to_string ();
            this.item.style ();
        });

        shape_bar.add (background_color_button);

        stack.add_named (shape_bar, SHAPE);
    }

    private void build_canvasbar () {

    }
}
