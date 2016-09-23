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
    private Gtk.Label label;
    private Gtk.Entry entry;
    private Gtk.Stack stack;

    public string font = "Open Sans";
    public int font_size = 14;
    public string font_color = "#fff";

    public bool bold = false;
    public bool italics = false;
    public bool underlined = false;

    private bool editing = false;

    const string TEXT_STYLE_CSS = """
        .colored {
            color: %s;

            font: %s;
            font-size: %dpx;
            background: 0;
        }
    """;

    public TextItem (Canvas canvas, Json.Object? save_data = null) {
        this.save_data = save_data;

        label = new Gtk.Label (_("Click to add text..."));
        label.halign = Gtk.Align.CENTER;
        label.valign = Gtk.Align.CENTER;
        label.expand = true;

        entry = new Gtk.Entry ();
        entry.get_style_context ().remove_class ("entry");
        entry.xalign = 0.5f;

        stack = new Gtk.Stack ();
        stack.set_transition_type (Gtk.StackTransitionType.NONE);

        stack.add_named (label, "label");
        stack.add_named (entry, "entry");
        stack.set_visible_child_name ("label");

        grid.attach (stack, 0, 0, 3, 2);

        entry.changed.connect (() => {
            label.label = entry.text;
        });

        this.clicked.connect (() => {
            if (!editing) {
                editing = true;
                stack.set_visible_child_name ("entry");
                entry.grab_focus ();
            }
        });

        entry.activate.connect (() => {
            unselect ();
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
            entry.text = text;
        }

        font_size = (int) save_data.get_int_member ("font-size");
        font = save_data.get_string_member ("font");
        font_color = save_data.get_string_member ("color");
    }

    protected override string serialise_item () {
        return """"type":"text","text": "%s","font": "%s","color": "%s","font-size": %d""".printf (label.label, font, font_color, font_size);
    }

    public override void style () {
        var provider = new Gtk.CssProvider ();
        var context = get_style_context ();

        var colored_css = TEXT_STYLE_CSS.printf (font_color, font, (int) (4 * font_size * (Canvas.current_ratio)));

        provider.load_from_data (colored_css, colored_css.length);

        context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        un_select ();
    }
}
