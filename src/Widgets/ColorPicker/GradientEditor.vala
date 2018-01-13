/*
* Copyright (c) 2018 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

public class Spice.GradientEditor : Gtk.Grid {
    public static Regex color_regex;

    static construct {
        try {
            color_regex = new Regex ("""(#.{3,6} )|rgba?\([0-9]{1,},[0-9]{1,},[0-9]{1,}(\)|,(0|1).?[0-9]{0,}\))""", 0);
        } catch (Error e) {
            error ("Regex failed: %s", e.message);
        }
    }

    public signal void color_selected (string color);
    public Gtk.ComboBoxText gradient_type;

    public ColorButton preview;
    public ColorButton color1;
    public ColorButton color2;

    public int selected_color = 0;

    public string gradient_color {
        get {
            return _gradient_color;
        } set {
            _gradient_color = value;
            parse_gradient (value);
        }
    }

    private string _gradient_color;

    private unowned ColorPicker color_picker;

    public GradientEditor (ColorPicker _color_picker) {
        color_picker = _color_picker;
        make_gradient_view ();
    }

    private void make_gradient_view () {
        var gradient_grid = new Gtk.Grid ();
        gradient_grid.row_spacing = 6;
        gradient_grid.margin_left = 6;

        var color1_label = new Gtk.Label (_("Color 1:"));
        var color2_label = new Gtk.Label (_("Color 2:"));

        color1_label.get_style_context ().add_class ("h4");
        color2_label.get_style_context ().add_class ("h4");

        color1_label.halign = Gtk.Align.END;
        color2_label.halign = Gtk.Align.END;

        color1_label.margin_right = 6;
        color2_label.margin_right = 6;

        color1 = new ColorButton ("red");
        color2 = new ColorButton ("orange");

        color1.margin_right = 6;
        color2.margin_right = 6;

        preview = new ColorButton ("");
        preview.get_style_context ().add_class ("flat");
        preview.set_size_request (100, 120);

        color1.clicked.connect (() => {
            selected_color = 1;
            color_selected (color1.color);
        });

        color2.clicked.connect (() => {
            selected_color = 2;
            color_selected (color2.color);
        });

        preview.clicked.connect (() => {
            selected_color = 3;
            color_selected (preview.color);
        });

        color1.grab_focus ();

        var preview_box = new Gtk.Grid ();
        preview_box.margin = 6;
        preview_box.get_style_context ().add_class ("card");
        preview_box.add (preview);

        gradient_type = new Gtk.ComboBoxText ();
        gradient_type.margin = 3;
        gradient_type.vexpand = true;
        gradient_type.valign = Gtk.Align.END;

        gradient_type.append ("to bottom", _("Vertical"));
        gradient_type.append ("to right", _("Horizontal"));
        //gradient_type.add_entry ("radial", "Radial"); TODO: Gtk doesn't support radial gradients just yet
        gradient_type.active = 0;

        gradient_type.changed.connect (() => {
            color_picker.color = make_gradient ();
            color_picker.color_picked (color_picker.color);
        });

        gradient_grid.attach (preview_box,   1, 1, 2, 3);
        gradient_grid.attach (color1_label,  0, 4, 2, 1);
        gradient_grid.attach (color1,        2, 4, 2, 1);
        gradient_grid.attach (color2_label,  0, 5, 2, 1);
        gradient_grid.attach (color2,        2, 5, 1, 1);
        gradient_grid.attach (gradient_type, 0, 6, 3, 1);

        add (gradient_grid);
    }

    public void parse_gradient (string color) {
        if (color.contains ("gradient")) {
            MatchInfo mi;
            string colors[2] = {"", ""};

            if (color_regex.match (color, 0 , out mi)) {
                int count = 0, pos_start = 0, pos_end = 0;

                try {
                    do {
                        mi.fetch_pos (0, out pos_start, out pos_end);
                        string found_color = mi.fetch (0);
                        if (pos_start == pos_end) {
                            break;
                        }

                        colors[count++] = found_color;
                    } while (mi.next () || count < 2);
                } catch (Error e) {
                    warning ("Could not find gradient parts: %s", e.message);
                    return;
                }
            }

            color1.color = colors[0].strip ();
            color2.color = colors[1].strip ();

            if (color.contains ("to bottom")) {
                gradient_type.set_active_id ("to bottom");
            } else if (color.contains ("to right")) {
                gradient_type.set_active_id ("to right");
            }
        } else {
            color1.color = color;
            color2.color = color;
        }
    }

    public string make_gradient () {
        return "linear-gradient(%s, %s 0%, %s 100%)".printf (gradient_type.active_id, color1.color, color2.color);
    }
}