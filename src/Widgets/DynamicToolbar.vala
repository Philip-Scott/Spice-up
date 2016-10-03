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

    // Text Toolbar
    private Pango.FontFamily[] families;
    private Gee.HashMap<string, Pango.FontFamily> family_cache;
    private Gee.HashMap<string, Array<Pango.FontFace>> face_cache;
    private Spice.EntryCombo font_button;
    private Gtk.ColorButton text_color_button;
    private Spice.EntryCombo font_size;
    private Spice.EntryCombo font_type;

    // Color Toolbar
    private Gtk.ColorButton background_color_button;

    // Canvas Bar

    // Common Bar

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

            reset_font_type (((TextItem) item).font);
            font_type.text = ((TextItem) item).font_style;

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

        font_type = new Spice.EntryCombo (true, true);
        font_type.max_length = 10;
        font_type.editable = false;

        family_cache = new Gee.HashMap<string, Pango.FontFamily> ();
        face_cache = new Gee.HashMap<string, Array<Pango.FontFace>> ();
        font_button = new Spice.EntryCombo (true, true);
        create_pango_context ().list_families (out families);

        foreach (var family in families) {
             var provider = new Gtk.CssProvider ();
             var context = font_button.add_entry (family.get_name ()).get_style_context ();
             var colored_css = TEXT_STYLE_CSS.printf (family.get_name ());

             provider.load_from_data (colored_css, colored_css.length);
             context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
             family_cache.set (family.get_name ().down(), family);
        }

        font_button.activated.connect (() => {
            reset_font_type (font_button.text);
            update_text_properties ();
        });

        font_type.activated.connect (() => {
            update_text_properties ();
        });

        int[] font_sizes = {5, 7, 9, 12, 16, 21, 28, 37, 42, 50, 67};
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
        text_bar.add (font_type);
        text_bar.add (text_color_button);

        stack.add_named (text_bar, TEXT);
    }

    private void reset_font_type (string selected_family) {
        string key = selected_family.down ();

        if (selected_family != null && selected_family != "" && family_cache.has_key (key)) {
            if (key == font_type.text) return;

            Array<Pango.FontFace> font_faces;

            if (face_cache.has_key (key)) {
                font_faces = face_cache.get (key);
            } else {
                Pango.FontFace[] temp_face;
                var family = family_cache.get (key);
                family.list_faces (out temp_face);
                font_faces = new Array<Pango.FontFace>();
                foreach (var face in temp_face) {
                    font_faces.append_val (face);
                }

                face_cache.set (key, font_faces);
            }

            font_type.clear_all ();

            for (int i = 0; i < font_faces.length ; i++) {
                font_type.add_entry (font_faces.index (i).get_face_name ());
            }
        }
    }

    private void update_text_properties () {
        if (item != null && item is TextItem && !selecting) {
            TextItem text = (TextItem) item;
            text.font_color = text_color_button.rgba.to_string ();
            text.font = font_button.text;
            text.font_style = font_type.text;
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

        var canvas_background = new Spice.ColorPicker ();
        var canvas_gradient_background = new Spice.ColorPicker ();
        canvas_gradient_background.gradient = true;

        canvas_bar.add (canvas_background);
        canvas_bar.add (canvas_gradient_background);

        stack.add_named (canvas_bar, CANVAS);
    }

    private void update_canvas_properties () {
        if (item == null && !selecting) {
            //color.background_color = background_color_button.rgba.to_string ();
        }
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
