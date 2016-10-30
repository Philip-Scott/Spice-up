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

public class Spice.Widgets.TextToolbar : Spice.Widgets.Toolbar {
    private Pango.FontFamily[] families;
    private Gee.HashMap<string, Pango.FontFamily> family_cache;
    private Gee.HashMap<string, Array<Pango.FontFace>> face_cache;
    private Granite.Widgets.ModeButton justification;
    private Spice.EntryCombo font_button;
    private Spice.ColorPicker text_color_button;
    private Spice.EntryCombo font_size;
    private Spice.EntryCombo font_type;

    const string TEXT_STYLE_CSS = """
        .label {
            font: %s;
            font-size: 14px;
        }
    """;

    construct {
        text_color_button = new Spice.ColorPicker ();
        text_color_button.set_tooltip_text (_("Font color"));

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

        int[] font_sizes = {5, 7, 9, 12, 16, 21, 28, 37, 42, 50, 67};
        font_size = new Spice.EntryCombo ();
        font_size.set_tooltip_text (_("Font size"));
        font_size.max_length = 3;

        foreach (var size in font_sizes) {
            font_size.add_entry (size.to_string ());
        }

        justification = new Granite.Widgets.ModeButton ();
        justification.append_icon ("format-justify-left-symbolic", Gtk.IconSize.MENU);
        justification.append_icon ("format-justify-center-symbolic", Gtk.IconSize.MENU);
        justification.append_icon ("format-justify-right-symbolic", Gtk.IconSize.MENU);
        justification.append_icon ("format-justify-fill-symbolic", Gtk.IconSize.MENU);

        foreach (var child in justification.get_children ()) {
            child.get_style_context ().add_class ("spice");
        }

        add (font_button);
        add (font_size);
        add (font_type);
        add (text_color_button);
        add (justification);

        connect_signals ();
    }

    private void connect_signals () {
        text_color_button.color_picked.connect (() => {
            var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,string>.item_changed (this.item as TextItem, "font-color");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_properties ();
        });

        font_size.activated.connect (() => {
            var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,int>.item_changed (this.item as TextItem, "font-size");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_properties ();
        });

        justification.mode_changed.connect ((widget) => {
            if (!selecting) {
                var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,int>.item_changed (this.item as TextItem, "justification");
                Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
                update_properties ();
            }
        });

        font_button.activated.connect (() => {
            reset_font_type (font_button.text);

            var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,string>.item_changed (this.item as TextItem,  "font");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);

            update_properties ();
        });

        font_type.activated.connect (() => {
            var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,string>.item_changed (this.item as TextItem, "font-style");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_properties ();
        });

    }

    protected override void item_selected (Spice.CanvasItem? item) {
        font_button.text = ((TextItem) item).font;
        font_size.text = ((TextItem) item).font_size.to_string ();

        reset_font_type (((TextItem) item).font);
        font_type.text = ((TextItem) item).font_style;

        text_color_button.color = ((TextItem) item).font_color;
        justification.set_active (((TextItem) item).justification);
    }

    public override void update_properties () {
        TextItem text = (TextItem) item;
        text.font_color = text_color_button.color;
        text.font = font_button.text;
        text.font_style = font_type.text;
        text.font_size = int.parse (font_size.text);
        text.justification = justification.selected;

        item.style ();
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
}
