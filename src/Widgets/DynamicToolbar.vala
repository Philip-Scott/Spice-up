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

    private SlideManager manager;
    private CanvasItem? item = null;
    private Gtk.Stack stack;

    private bool selecting = false;

    // Text Toolbar
    private Pango.FontFamily[] families;
    private Gee.HashMap<string, Pango.FontFamily> family_cache;
    private Gee.HashMap<string, Array<Pango.FontFace>> face_cache;
    private Granite.Widgets.ModeButton justification;
    private Spice.EntryCombo font_button;
    private Spice.ColorPicker text_color_button;
    private Spice.EntryCombo font_size;
    private Spice.EntryCombo font_type;

    // Color Toolbar
    private Spice.ColorPicker background_color_button;

    // Canvas Bar
    private Spice.ColorPicker canvas_gradient_background;
    private Spice.EntryCombo canvas_pattern;

    // Common Bar

    const string TEXT_STYLE_CSS = """
        .label {
            font: %s;
            font-size: 14px;
        }
    """;

    public DynamicToolbar (SlideManager slide_manager) {
        manager = slide_manager;

        stack = new Gtk.Stack ();
        stack.set_transition_type (Gtk.StackTransitionType.SLIDE_DOWN);

        get_style_context ().add_class ("toolbar");
        get_style_context ().add_class ("inline-toolbar");

        build_textbar ();
        build_imagebar ();
        build_shapebar ();
        build_canvasbar ();
        build_common ();

        this.add (stack);
        this.add (common_bar);

        Spice.Services.HistoryManager.get_instance ().action_called.connect ((i) => {
            item_selected (i);
        });
    }

    public void item_selected (Spice.CanvasItem? item) {
        selecting = true;
        this.item = item;
        if (item == null) {
            stack.set_visible_child_name (CANVAS);
            canvas_gradient_background.color = manager.current_slide.canvas.background_color;
            canvas_pattern.text = manager.current_slide.canvas.background_pattern;
        } else if (item is TextItem) {
            stack.set_visible_child_name (TEXT);
            font_button.text = ((TextItem) item).font;
            font_size.text = ((TextItem) item).font_size.to_string ();

            reset_font_type (((TextItem) item).font);
            font_type.text = ((TextItem) item).font_style;

            text_color_button.color = ((TextItem) item).font_color;
            justification.set_active (((TextItem) item).justification);
        } else if (item is ColorItem) {
            stack.set_visible_child_name (SHAPE);

            background_color_button.color = ((ColorItem) item).background_color;
        } else if (item is ImageItem) {
            stack.set_visible_child_name (IMAGE);
        }

        selecting = false;
    }

    private void build_textbar () {
        text_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        text_bar.border_width = 6;

        text_color_button = new Spice.ColorPicker ();
        text_color_button.set_tooltip_text (_("Font color"));
        text_color_button.color_picked.connect (() => {
            var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,string>.item_changed (this.item as TextItem, "font-color");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_text_properties ();
        });

        font_type = new Spice.EntryCombo (true, true);
        font_type.set_tooltip_text (_("Font Style"));
        font_type.max_length = 10;
        font_type.editable = false;

        family_cache = new Gee.HashMap<string, Pango.FontFamily> ();
        face_cache = new Gee.HashMap<string, Array<Pango.FontFace>> ();
        font_button = new Spice.EntryCombo (true, true);
        font_button.set_tooltip_text (_("Font"));
        create_pango_context ().list_families (out families);

        foreach (var family in families) {
            var entry = font_button.add_entry (family.get_name ());
            Utils.set_style (entry, TEXT_STYLE_CSS.printf (family.get_name ()));
            family_cache.set (family.get_name ().down(), family);
        }

        font_button.activated.connect (() => {
            reset_font_type (font_button.text);

            var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,string>.item_changed (this.item as TextItem,  "font");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);

            update_text_properties ();
        });

        font_type.activated.connect (() => {
            var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,string>.item_changed (this.item as TextItem, "font-style");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_text_properties ();
        });

        int[] font_sizes = {5, 7, 9, 12, 16, 21, 28, 37, 42, 50, 67};
        font_size = new Spice.EntryCombo ();
        font_size.set_tooltip_text (_("Font size"));
        font_size.max_length = 3;

        foreach (var size in font_sizes) {
            font_size.add_entry (size.to_string ());
        }

        font_size.activated.connect (() => {
            var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,int>.item_changed (this.item as TextItem, "font-size");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_text_properties ();
        });

        justification = new Granite.Widgets.ModeButton ();
        justification.append_icon ("format-justify-left-symbolic", Gtk.IconSize.MENU);
        justification.append_icon ("format-justify-center-symbolic", Gtk.IconSize.MENU);
        justification.append_icon ("format-justify-right-symbolic", Gtk.IconSize.MENU);
        justification.append_icon ("format-justify-fill-symbolic", Gtk.IconSize.MENU);

        justification.mode_changed.connect ((widget) => {
            if (!selecting) {
                var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,int>.item_changed (this.item as TextItem, "justification");
                Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
                update_text_properties ();
            }
        });

        foreach (var child in justification.get_children ()) {
            child.get_style_context ().add_class ("spice");
        }

        text_bar.add (font_button);
        text_bar.add (font_size);
        text_bar.add (font_type);
        text_bar.add (text_color_button);
        text_bar.add (justification);

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
            text.font_color = text_color_button.color;
            text.font = font_button.text;
            text.font_style = font_type.text;
            text.font_size = int.parse (font_size.text);
            text.justification = justification.selected;

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
        shape_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        shape_bar.border_width = 6;

        background_color_button = new Spice.ColorPicker ();
        background_color_button.set_tooltip_text (_("Shape color"));
        background_color_button.gradient = true;

        background_color_button.color_picked.connect ((color) => {
            var action = new Spice.Services.HistoryManager.HistoryAction<ColorItem,string>.item_changed (this.item as ColorItem, "background-color");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_shape_properties ();
        });

        shape_bar.add (background_color_button);

        stack.add_named (shape_bar, SHAPE);
    }

    private void update_shape_properties () {
        if (item != null && item is ColorItem && !selecting) {
            ColorItem color = (ColorItem) item;
            color.background_color = background_color_button.color;

            this.item.style ();
        }
    }

    private void build_canvasbar () {
        canvas_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        canvas_bar.border_width = 6;

        canvas_gradient_background = new Spice.ColorPicker ();
        canvas_gradient_background.gradient = true;
        canvas_gradient_background.set_tooltip_text (_("Background color"));

        canvas_gradient_background.color_picked.connect (() => {
            var action = new Spice.Services.HistoryManager.HistoryAction<Canvas,string>.canvas_changed (this.manager.current_slide.canvas, "background-color");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_canvas_properties ();
        });

        canvas_pattern = new Spice.EntryCombo (true, true);
        canvas_pattern.set_tooltip_text (_("Background pattern"));
        canvas_pattern.editable = false;

        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/3px-tile.png", _("3px tile"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/45-degree-fabric-dark.png", _("Fabric dark"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/45-degree-fabric-light.png", _("Fabric light"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/beige-paper.png", _("Beige paper"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/black-linen.png", _("Black linen"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/bright-squares.png", _("Bright squares"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/flowers.png", _("Flowers"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/hexellence.png", _("Hexellence"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/gplay.png", _("Gplay"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/inspiration-geometry.png", _("Geometry"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/dark-geometric.png", _("Dark geometric"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/light-wool.png", _("Light wool"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/silver-scales.png", _("Silver scales"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/subtle-freckles.png", _("Subtle grid"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/subtle-grey.png", _("Subtle squares"));
        canvas_pattern.add_entry ("/usr/share/spice-up/assets/patterns/xv.png", _("XV"));
        canvas_pattern.add_entry ("", _(" None"));

        canvas_pattern.activated.connect (() => {
            var action = new Spice.Services.HistoryManager.HistoryAction<Canvas,string>.canvas_changed (this.manager.current_slide.canvas, "background-pattern");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_canvas_properties ();
        });

        canvas_bar.add (canvas_gradient_background);
        canvas_bar.add (canvas_pattern);
        stack.add_named (canvas_bar, CANVAS);
    }

    private void update_canvas_properties () {
        if (item == null && !selecting) {
            manager.current_slide.canvas.background_pattern = canvas_pattern.text;
            manager.current_slide.canvas.background_color = canvas_gradient_background.color;
            manager.current_slide.canvas.style ();
        }
    }

    private void build_common () {
        common_bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        common_bar.border_width = 6;
        common_bar.hexpand = true;
        common_bar.halign = Gtk.Align.END;

        var delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.MENU);
        delete_button.set_tooltip_text (_("Delete"));
        delete_button.get_style_context ().add_class ("spice");
        delete_button.clicked.connect (() => {
            this.item.visible = false;
            item_selected (null);
        });

        var to_top = new Gtk.Button.from_icon_name ("go-up-symbolic", Gtk.IconSize.MENU);
        to_top.get_style_context ().add_class ("spice");
        to_top.set_tooltip_text (_("Move up"));

        var to_bottom = new Gtk.Button.from_icon_name ("go-down-symbolic", Gtk.IconSize.MENU);
        to_bottom.get_style_context ().add_class ("spice");
        to_bottom.set_tooltip_text (_("Move down"));

        var position_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        position_grid.get_style_context ().add_class ("linked");
        position_grid.add (to_top);
        position_grid.add (to_bottom);

        to_top.clicked.connect (() => {
            if (this.item != null) {
                this.manager.current_slide.canvas.move_up (this.item);
            } else {
                this.manager.move_up (this.manager.current_slide);
            }
        });

        to_bottom.clicked.connect (() => {
            if (this.item != null) {
                this.manager.current_slide.canvas.move_down (this.item);
            } else {
                this.manager.move_down (this.manager.current_slide);
            }
        });

        common_bar.add (position_grid);
        common_bar.add (delete_button);
    }
}
