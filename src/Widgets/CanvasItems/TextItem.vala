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

    public int justification {get; set; default = 1; }
    public int font_size {get; set; default = 16; }
    public string font {get; set; default = "Open Sans"; }
    public string font_color {get; set; default = "#fff"; }
    public string font_style {get; set; default = "Regular"; }

    private string text_;
    public string text {
        get {
            text_ = entry.buffer.text;
            return text_;
        } set {
            if (value == "") {
                entry.buffer.text = _("Click to add text...");
            } else {
                entry.buffer.text = value;
            }
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
        .colored {
            color: %s;
            padding: 0px;
            font: %s %s;
            font-size: %spx;
            background: 0;
        }
    """;

    public TextItem (Canvas canvas, Json.Object? save_data = null) {
        base (canvas);

        this.save_data = save_data;

        entry = new Gtk.TextView ();
        entry.buffer.text = (_("Click to add text..."));
        entry.justification = Gtk.Justification.CENTER;
        entry.set_wrap_mode (Gtk.WrapMode.WORD);
        entry.can_focus = true;

        grid.attach (entry, 0, 0, 3, 2);

        this.check_position.connect (() => {
            update_size ();
        });

        Timeout.add (100, () => {
            update_size ();
            return true;
        });

        this.clicked.connect (() => {
            if (!editing) {
                if (entry.buffer.text == _("Click to add text...")) {
                    entry.buffer.text = "";
                }

                editing = true;
                Timeout.add (1, () => {
                    update_size ();
                    return false;
                });
            }
        });

        un_select.connect (() => {
            editing = false;
            entry.select_all (false);
            if (entry.buffer.text == "") {
                entry.buffer.text = _("Click to add text...");
            }
        });

        canvas.ratio_changed.connect ((ratio) => {
            style ();
        });

        editing = false;

        load_data ();

        style ();
    }

    // Gtk Glitches are bad :(
    private void update_size () {
        entry.valign = Gtk.Align.FILL;
        entry.halign = Gtk.Align.CENTER;
        entry.expand = true;
        entry.valign = Gtk.Align.CENTER;
        entry.halign = Gtk.Align.FILL;
    }

    protected override void load_item_data () {
        var text = save_data.get_string_member ("text");
        if (text != null) {
            entry.buffer.text = text;
        }

        font_size = (int) save_data.get_int_member ("font-size");
        font = save_data.get_string_member ("font");

        var style = save_data.get_string_member ("font-style");
        if (style != null) {
            font_style = style;
        }

        int64? justify = save_data.get_int_member ("justification");
        if (justify != null) {
            justification = (int) justify;
        }

        font_color = save_data.get_string_member ("color");
    }

    protected override string serialise_item () {
        return """"type":"text","text": "%s","font": "%s","color": "%s","font-size": %d, "font-style":"%s", "justification": %d """.printf (entry.buffer.text, font, font_color, font_size, font_style, justification);
    }

    public override void style () {
        var converted_font_size = (4.0 * canvas.current_ratio * font_size);

        if (converted_font_size > 0) {
            Utils.set_style (this, TEXT_STYLE_CSS.printf (font_color, font, font_style, converted_font_size.to_string ().replace (",", ".")));
        }

        switch (justification) {
            case 0:
                entry.justification = Gtk.Justification.LEFT;
                break;
            case 1:
                entry.justification = Gtk.Justification.CENTER;
                break;
            case 2:
                entry.justification = Gtk.Justification.RIGHT;
                break;
            case 3:
                entry.justification = Gtk.Justification.FILL;
                break;
        }
    }
}
