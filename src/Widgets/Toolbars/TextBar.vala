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
    private Granite.Widgets.ModeButton align;
    private Spice.EntryCombo font_button;
    private Spice.ColorChooser text_color_button;
    private Spice.EntryCombo font_size;
    private Spice.EntryCombo font_type;

    private Gtk.Image align_button_image;

    private string[] JUSTIFICATION_TRANSLATIONS = {_("Left"), _("Center"), _("Right"), _("Justify")};
    private string[] ALIGN_TRANSLATIONS = {_("Top"), _("Middle"), _("Bottom")};

    #if GTK_3_22
    const string TEXT_STYLE_CSS = """
        label {
            font: 16px '%s';
        }
    """;

    const string FONT_STYLE_CSS = """
        label {
            font: %i %s 16px '%s';
        }
    """;
    #else
    const string TEXT_STYLE_CSS = """
        .label {
            font: %s;
            font-size: 14px;
        }
    """;

    const string FONT_STYLE_CSS = """
        .label {
            font: %s;
            font-size: 14px;
            font-style: %s;
            font-weight: %i;
        }
    """;
    #endif

    construct {
        text_color_button = new Spice.ColorChooser ();
        text_color_button.set_tooltip_text (_("Font color"));

        font_type = new Spice.EntryCombo (true, true);
        font_type.set_tooltip_text (_("Font Style"));
        font_type.max_length = 10;
        font_type.editable = false;

        family_cache = new Gee.HashMap<string, Pango.FontFamily> ();
        face_cache = new Gee.HashMap<string, Array<Pango.FontFace>> ();
        font_button = new Spice.EntryCombo (true, true, true);
        font_button.set_tooltip_text (_("Font"));
        font_button.editable = false;
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

        align_button_image = new Gtk.Image.from_icon_name ("format-justify-fill-symbolic", Gtk.IconSize.MENU);

        var align_button = new Gtk.Button ();
        align_button.get_style_context ().add_class ("spice");
        align_button.set_tooltip_text (_("Align"));
        align_button.add (align_button_image);

        var align_grid = new Gtk.Grid ();
        align_grid.orientation = Gtk.Orientation.VERTICAL;
        align_grid.row_spacing = 6;
        align_grid.margin = 6;

        var align_popover = new Gtk.Popover (align_button);
        align_popover.position = Gtk.PositionType.BOTTOM;
        align_popover.add (align_grid);

        align_button.clicked.connect (() => {
            align_popover.show_all ();
        });

        justification = new Granite.Widgets.ModeButton ();
        justification.mode_added.connect ((index, widget) => {
            widget.set_tooltip_text (JUSTIFICATION_TRANSLATIONS[index]);
            widget.margin = 3;
        });

        justification.append_icon ("format-justify-left-symbolic", Gtk.IconSize.MENU);
        justification.append_icon ("format-justify-center-symbolic", Gtk.IconSize.MENU);
        justification.append_icon ("format-justify-right-symbolic", Gtk.IconSize.MENU);
        justification.append_icon ("format-justify-fill-symbolic", Gtk.IconSize.MENU);

        foreach (var child in justification.get_children ()) {
            child.get_style_context ().add_class ("spice");
        }

        align = new Granite.Widgets.ModeButton ();
        align.mode_added.connect ((index, widget) => {
            widget.set_tooltip_text (ALIGN_TRANSLATIONS[index]);
            widget.margin = 3;
        });

        align.append (new Gtk.Image.from_resource ("/com/github/philip-scott/spice-up/align-top-symbolic"));
        align.append (new Gtk.Image.from_resource ("/com/github/philip-scott/spice-up/align-middle-symbolic"));
        align.append (new Gtk.Image.from_resource ("/com/github/philip-scott/spice-up/align-bottom-symbolic"));

        foreach (var child in align.get_children ()) {
            child.get_style_context ().add_class ("spice");
        }

        add (text_color_button);
        add (font_button);
        add (font_size);
        add (font_type);
        add (align_button);

        align_grid.add (justification);
        align_grid.add (align);

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
            align_button_image.icon_name = (widget as Gtk.Image).icon_name;

            if (!selecting) {
                var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,int>.item_changed (this.item as TextItem, "justification");
                Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
                update_properties ();
            }
        });

        align.mode_changed.connect ((widget) => {
            if (!selecting) {
                var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,int>.item_changed (this.item as TextItem, "align");
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

    protected override void item_selected (Spice.CanvasItem? item, bool new_item = false) {
        if (new_item) {
            update_properties ();
            return;
        }

        font_button.text = ((TextItem) item).font;
        font_size.text = ((TextItem) item).font_size.to_string ();

        reset_font_type (((TextItem) item).font);
        font_type.text = ((TextItem) item).font_style;

        text_color_button.color = ((TextItem) item).font_color;
        justification.set_active (((TextItem) item).justification);
        align.set_active (((TextItem) item).align);
    }

    public override void update_properties () {
        TextItem text = (TextItem) item;
        text.font_color = text_color_button.color;
        text.font = font_button.text;
        text.font_style = font_type.text;
        text.font_size = int.parse (font_size.text);
        text.justification = justification.selected;
        text.align = align.selected;

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

            var family_name = family_cache.get (key).get_name ();

            for (int i = 0; i < font_faces.length ; i++) {
                var font_face = font_faces.index (i);
                var entry = font_type.add_entry (font_face.get_face_name ());

                var description = font_face.describe();
                string style = "normal";
                switch (description.get_style ()) {
                   case Pango.Style.OBLIQUE: style = "oblique"; break;
                   case Pango.Style.ITALIC: style = "italic"; break;
                }

                int weight = 400;
                switch (description.get_weight ()) {
                    case Pango.Weight.THIN: weight = 100; break;
                    case Pango.Weight.ULTRALIGHT: weight = 200; break;
                    case Pango.Weight.LIGHT: weight = 300; break;
                    case Pango.Weight.SEMILIGHT: weight = 350; break;
                    case Pango.Weight.BOOK: weight = 380; break;
                    case Pango.Weight.NORMAL: weight = 400; break;
                    case Pango.Weight.MEDIUM: weight = 500; break;
                    case Pango.Weight.SEMIBOLD: weight = 600; break;
                    case Pango.Weight.BOLD: weight = 700; break;
                    case Pango.Weight.ULTRABOLD: weight = 800; break;
                    case Pango.Weight.HEAVY: weight = 900; break;
                    case Pango.Weight.ULTRAHEAVY: weight = 1000; break;
                }
                #if GTK_3_22
                Utils.set_style (entry, FONT_STYLE_CSS.printf (weight, style, family_name));
                #else
                Utils.set_style (entry, FONT_STYLE_CSS.printf (family_name, style, weight));
                #endif
            }
        }
    }
}
