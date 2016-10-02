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
    private Gtk.Box canvas_bar;
    private Gtk.Box common_bar;

    private CanvasItem? item = null;
    private Gtk.Stack stack;

    private bool selecting = false;

    //Text Toolbar
    private Spice.EntryCombo font_button;
    private Gtk.ColorButton text_color_button;
    private Spice.EntryCombo font_size;

    //Color Toolbar
    private Gtk.ColorButton background_color_button;

    //Common Bar

    const string TEXT_STYLE_CSS = """
        .label {
            font: %s;
            font-size: 14;
        }
    """;

    public DynamicToolbar () {
        stack = new Gtk.Stack ();
        stack.set_transition_type (Gtk.StackTransitionType.OVER_DOWN);

        get_style_context ().add_class ("toolbar");
        get_style_context ().add_class ("inline-toolbar");

        build_textbar ();
        build_imagebar ();
        build_shapebar ();
        build_canvasbar ();
        build_common ();

        this.add (stack);
        this.add (common_bar);
    }

    public void item_selected (Spice.CanvasItem? item) {
        selecting = true;
        this.item = item;
        if (item == null) {
            stack.set_visible_child_name (CANVAS);
        } else if (item is TextItem) {
            stack.set_visible_child_name (TEXT);
            font_button.text = ((TextItem) item).font;
            font_size.text = ((TextItem) item).font_size.to_string ();

            Gdk.RGBA rgba = Gdk.RGBA ();
            rgba.parse (((TextItem) item).font_color);
            text_color_button.rgba = rgba;
        } else if (item is ColorItem) {
            stack.set_visible_child_name (SHAPE);

            Gdk.RGBA rgba = Gdk.RGBA ();
            rgba.parse (((ColorItem) item).background_color);

            background_color_button.rgba = rgba;
        } else if (item is ImageItem) {
            stack.set_visible_child_name (IMAGE);
        }

        selecting = false;
    }

    private void build_textbar () {
        text_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        text_bar.border_width = 6;
        text_bar.spacing = 6;

        text_color_button = new Gtk.ColorButton ();
        text_color_button.color_set.connect (() => {
            update_text_properties ();
        });

        font_button = new Spice.EntryCombo (true, true);

        Pango.FontFamily[] families;
        create_pango_context ().list_families (out families);

        foreach (var family in families) {
             var provider = new Gtk.CssProvider ();
             var context = font_button.add_entry (family.get_name ()).get_style_context ();

             var colored_css = TEXT_STYLE_CSS.printf (family.get_name ());

             provider.load_from_data (colored_css, colored_css.length);
             context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        font_button.activated.connect (() => {
            update_text_properties ();
        });

        int[] font_sizes = {6, 7, 8, 9, 10, 12, 14, 16, 18, 20, 24, 28, 32, 38, 42};
        font_size = new Spice.EntryCombo ();
        font_size.max_length = 3;

        foreach (var size in font_sizes) {
            font_size.add_entry (size.to_string ());
        }

        font_size.activated.connect (() => {
            update_text_properties ();
        });

        text_bar.add (font_button);
        text_bar.add (font_size);
        text_bar.add (text_color_button);

        stack.add_named (text_bar, TEXT);
    }

    private void update_text_properties () {
        if (item != null && item is TextItem && !selecting) {
            TextItem text = (TextItem) item;
            text.font_color = text_color_button.rgba.to_string ();
            text.font = font_button.text;
            text.font_size = int.parse (font_size.text);

            this.item.style ();
        }
    }

    private void build_imagebar () {
        image_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        image_bar.border_width = 6;
        image_bar.spacing = 6;

        stack.add_named (image_bar, IMAGE);
    }

    private void build_shapebar () {
        shape_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        shape_bar.border_width = 6;
        shape_bar.spacing = 6;

        background_color_button = new Gtk.ColorButton ();
        background_color_button.use_alpha = true;

        background_color_button.color_set.connect (() => {
            update_shape_properties ();
        });

        shape_bar.add (background_color_button);

        stack.add_named (shape_bar, SHAPE);
    }

    private void update_shape_properties () {
        if (item != null && item is ColorItem && !selecting) {
            ColorItem color = (ColorItem) item;
            color.background_color = background_color_button.rgba.to_string ();

            this.item.style ();
        }
    }

    private void build_canvasbar () {
        canvas_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        canvas_bar.border_width = 6;
        canvas_bar.spacing = 6;

        stack.add_named (canvas_bar, CANVAS);
    }

    private void build_common () {
        common_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        common_bar.border_width = 6;
        common_bar.spacing = 6;
        common_bar.hexpand = true;
        common_bar.halign = Gtk.Align.END;

        var delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.MENU);
        delete_button.get_style_context ().add_class ("spice");
        delete_button.clicked.connect (() => {
            this.item.destroy ();
            item_selected (null);
        });

        common_bar.add (delete_button);
    }
}
