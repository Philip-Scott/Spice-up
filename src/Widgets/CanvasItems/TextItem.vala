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
    public Gtk.Label label;
    private Gtk.TextView entry;
    private Gtk.Stack stack;

    public string font {get; set; default = "Open Sans"; }
    public int font_size {get; set; default = 16; }
    public string font_color {get; set; default = "#fff"; }
    public string font_style {get; set; default = "Regular"; }

    public bool underlined = false;
    public int justification {get; set; default = 1; }

    private bool editing = false;

    const string TEXT_STYLE_CSS = """
        .colored {
            color: %s;
            padding: 0;
            font: %s %s;
            font-size: %fpx;
            background: 0;
        }
    """;

    public TextItem (Canvas canvas, Json.Object? save_data = null) {
        base (canvas);

        this.save_data = save_data;

        label = new Gtk.Label (_("Click to add text..."));
        label.justify = Gtk.Justification.CENTER;
        label.halign = Gtk.Align.CENTER;
        label.valign = Gtk.Align.CENTER;
        label.expand = true;
        label.wrap = true;
        label.xalign = 0.0f;

        entry = new Gtk.TextView ();
        entry.justification = Gtk.Justification.CENTER;
        entry.set_wrap_mode (Gtk.WrapMode.WORD);


        stack = new Gtk.Stack ();
        stack.set_transition_type (Gtk.StackTransitionType.NONE);

        stack.add_named (label, "label");
        stack.add_named (entry, "entry");
        stack.set_visible_child_name ("label");

        grid.attach (stack, 0, 0, 3, 2);

        entry.buffer.changed.connect (() => {
            label.label = entry.buffer.text;
        });

        this.check_position.connect (() => {
            entry.valign = Gtk.Align.FILL;
            entry.halign = Gtk.Align.CENTER;

            entry.expand = true;
            entry.valign = Gtk.Align.CENTER;
            entry.halign = Gtk.Align.FILL;
        });

        this.clicked.connect (() => {
            if (!editing) {
                editing = true;
                stack.set_visible_child_name ("entry");
                entry.valign = Gtk.Align.FILL;
                entry.halign = Gtk.Align.CENTER;

                entry.expand = true;
                entry.valign = Gtk.Align.CENTER;
                entry.halign = Gtk.Align.FILL;
                entry.grab_focus ();
            }
        });

        un_select.connect (() => {
            editing = false;
            stack.set_visible_child_name ("label");

            if (label.label == "") {
                label.label = _("Click to add text...");
            }
        });

        canvas.ratio_changed.connect ((ratio) => {
            style ();
        });

        load_data ();
        style ();
    }

    protected override void load_item_data () {
        var text = save_data.get_string_member ("text");
        if (text != null) {
            label.label = text;
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
        return """"type":"text","text": "%s","font": "%s","color": "%s","font-size": %d, "font-style":"%s", "justification": %d """.printf (label.label, font, font_color, font_size, font_style, justification);
    }

    public override void style () {
        var converted_font_size = 4.0 * canvas.current_ratio * font_size;

        if (converted_font_size > 0) {
            Utils.set_style (this, TEXT_STYLE_CSS.printf (font_color, font, font_style, converted_font_size));
            un_select ();
        }

        switch (justification) {
            case 0:
                label.justify = Gtk.Justification.LEFT;
                label.halign = Gtk.Align.START;
                entry.justification = Gtk.Justification.LEFT;
                break;
            case 1:
                label.justify = Gtk.Justification.CENTER;
                label.halign = Gtk.Align.CENTER;
                entry.justification = Gtk.Justification.CENTER;
                break;
            case 2:
                label.justify = Gtk.Justification.RIGHT;
                label.halign = Gtk.Align.END;
                entry.justification = Gtk.Justification.RIGHT;
                break;
            case 3:
                label.justify = Gtk.Justification.FILL;
                label.halign = Gtk.Align.FILL;
                entry.justification = Gtk.Justification.FILL;
                break;
        }
    }
}
