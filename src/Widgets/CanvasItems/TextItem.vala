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

public class Spice.TextItem : Spice.CanvasItem {
    private Gtk.TextView entry;
    private Gtk.Label label;
    private Gtk.Stack stack;

    public int justification {get; set; default = 1; }
    public int align { get; set; default = 1; }
    public int font_size {get; set; default = 16; }
    public string font {get; set; default = "Open Sans"; }
    public string font_color {get; set; default = "#fff"; }
    public string font_style {get; set; default = "Regular"; }

    public bool setting_text = false;
    public bool first_change_in_edit = false;
    public string previous_text = "";
    public string text {
        owned get {
            return previous_text;
        } set {
            setting_text = true;
            entry.buffer.text = value;

            if (value == "") {
                label.label = _("Click to add text...");
            } else {
                label.label = value;
            }

            previous_text = label.label;
            setting_text = false;
        }
    }

    public bool underlined = false;

    private bool editing {
        get {
            return entry.editable;
        } set {
            entry.editable = value;
            entry.cursor_visible = value;

            if (value) {
                entry.grab_focus ();
            }
        }
    }

    const string TEXT_STYLE_CSS = """
        .colored, .view text {
            color: %s;
            font: %s;
            padding: 0px;
            background: 0;
        }
    """;

    public TextItem (Canvas _canvas, Json.Object? _save_data = null) {
        Object (canvas: _canvas, save_data: _save_data);

        entry = new Gtk.TextView ();
        entry.justification = Gtk.Justification.CENTER;
        entry.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
        entry.valign = Gtk.Align.CENTER;
        entry.halign = Gtk.Align.FILL;
        entry.can_focus = true;
        entry.expand = true;

        label = new Gtk.Label (_("Click to add text..."));
        label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        label.expand = true;
        label.wrap = true;

        stack = new Gtk.Stack ();
        stack.homogeneous = false;

        stack.add_named (label, "label");
        stack.add_named (entry, "entry");
        stack.set_visible_child_name ("label");
        stack.expand = true;

        if (grid != null) {
            grid.attach (stack, 0, 0, 1, 1);
        }

        this.clicked.connect (() => {
            if (!editing) {
                first_change_in_edit = true;
                if (entry.buffer.text == _("Click to add text...")) {
                    entry.buffer.text = "";
                }

                stack.set_visible_child_name ("entry");

                var w = label.get_allocated_width ();
                var h = label.get_allocated_height ();

                entry.set_size_request (w, h);

                Timeout.add (80, () => {
                    entry.set_size_request (0, 0);
                    return false;
                });

                entry.queue_resize ();
                editing = true;
            }
        });

        un_select.connect (() => {
            editing = false;
            entry.select_all (false);

            text = entry.buffer.text;

            stack.set_visible_child_name ("label");
        });

        canvas.ratio_changed.connect ((ratio) => {
            style ();
        });

        editing = false;

        load_data ();

        entry.buffer.changed.connect (() => {
            if (!setting_text) {
                var action = new Spice.Services.HistoryManager.HistoryAction<TextItem,string>.item_changed (this as TextItem, "text");
                Spice.Services.HistoryManager.get_instance ().add_undoable_action (action, first_change_in_edit);
                first_change_in_edit = false;

                previous_text = entry.buffer.text;
            }
        });

        style ();
    }

    // Needed to fix GTK glitches
    public void resize_entry () {
        entry.queue_resize ();
    }

    protected override void load_item_data () {
        string? text_data = null;
        if (save_data.has_member ("text-data")) {
            text_data = save_data.get_string_member ("text-data");
        }

        if (text_data != null && text_data != "") {
            this.text = (string) Base64.decode (text_data);
        } else {
            var text = save_data.get_string_member ("text");
            if (text != null) {
                this.text = text;
            }
        }

        font_size = (int) save_data.get_int_member ("font-size");
        font = save_data.get_string_member ("font");

        if (save_data.has_member ("font-style")) {
            var _font_style = save_data.get_string_member ("font-style");
            font_style = _font_style;
        }

        if (save_data.has_member ("justification")) {
            int64? justify = save_data.get_int_member ("justification");
            justification = (int) justify;
        }

        if (save_data.has_member ("align")) {
            align = (int) save_data.get_int_member ("align");
        }

        font_color = save_data.get_string_member ("color");
    }

    protected override string serialise_item () {
        return """"type":"text","text": "","text-data": "%s","font": "%s","color": "%s","font-size": %d, "font-style":"%s", "justification": %d, "align": %d """.printf (Base64.encode (entry.buffer.text.data), font, font_color, font_size, font_style, justification, align);
    }

    public override void style () {
        #if GTK_3_22
        var converted_font_size = (5.3 * canvas.current_ratio * font_size);
        #else
        var converted_font_size = (4.0 * canvas.current_ratio * font_size);
        #endif

        if (converted_font_size > 0) {
            var font_css = get_font_css (font, font_style.down (), converted_font_size);
            var css = TEXT_STYLE_CSS.printf (font_color, font_css);
            Utils.set_style (this, css);
            Utils.set_style (entry, css);
        }

        switch (justification) {
            case 0:
                entry.justification = Gtk.Justification.LEFT;
                label.justify = Gtk.Justification.LEFT;
                label.halign = Gtk.Align.START;
                label.xalign = 0.0f;
                break;
            case 1:
                entry.justification = Gtk.Justification.CENTER;
                label.justify = Gtk.Justification.CENTER;
                label.halign = Gtk.Align.CENTER;
                label.xalign = 0.5f;
                break;
            case 2:
                entry.justification = Gtk.Justification.RIGHT;
                label.justify = Gtk.Justification.RIGHT;
                label.halign = Gtk.Align.END;
                label.xalign = 1.0f;
                break;
            case 3:
                entry.justification = Gtk.Justification.FILL;
                label.justify = Gtk.Justification.FILL;
                label.halign = Gtk.Align.FILL;
                label.xalign = 0.0f;
                break;
        }

        switch (align) {
            case 0:
                entry.valign = Gtk.Align.START;
                label.valign = Gtk.Align.START;
                break;
            case 1:
                entry.valign = Gtk.Align.CENTER;
                label.valign = Gtk.Align.CENTER;
                break;
            case 2:
                entry.valign = Gtk.Align.END;
                label.valign = Gtk.Align.END;
                break;
        }

        resize_entry ();
    }

    private string get_font_css (string font, string _font_style, double font_size) {
        var font_size_text = font_size.to_string ().replace (",", ".");

    #if GTK_3_22
        var font_style = _font_style.replace ("black", "900");
        font_style = font_style.replace ("extrabold", "800");
        font_style = font_style.replace ("semibold", "600");
        font_style = font_style.replace ("bold", "700");
        font_style = font_style.replace ("medium", "500");
        font_style = font_style.replace ("regular", "400");
        font_style = font_style.replace ("extralight", "300");
        font_style = font_style.replace ("light", "200");
        font_style = font_style.replace ("thin", "100");

        return "%s %spx '%s'".printf (font_style, font_size_text, font);
    #else
        return "%s %s;\n font-size: %spx;".printf (font, _font_style, font_size_text);
    #endif
    }
}
