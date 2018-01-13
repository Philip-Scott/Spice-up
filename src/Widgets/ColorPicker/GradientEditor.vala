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
    public signal void color_selected (int index, string color);
    public Gtk.ComboBoxText gradient_type;

    public ColorButton preview;
    private ColorButton color1;
    private ColorButton color2;

    public string gradient_color {
        get {
            return _gradient_color;
        } set {
            _gradient_color = value;
            parse_gradient (value);
        }
    }

    private Gradient gradient { get; set; }

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

        color1 = new ColorButton ("#fff");
        color2 = new ColorButton ("#fbb");

        color1.margin_right = 6;
        color2.margin_right = 6;

        preview = new ColorButton ("");
        preview.get_style_context ().add_class ("flat");
        preview.set_size_request (100, 120);

        color1.clicked.connect (() => {
            color_selected (1, color1.color);
        });

        color2.clicked.connect (() => {
            color_selected (2, color2.color);
        });

        preview.clicked.connect (() => {
            color_selected (-1, preview.color);
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
            this.gradient.direction = gradient_type.active_id;
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

    public void set_color (int step, string color) {
        gradient.get_color (step).color = color;
    }

    public void parse_gradient (string color) {
        if (color.contains ("gradient")) {
            gradient = new Gradient (color);

            color1.color = gradient.get_color (0).color;
            color2.color = gradient.get_color (1).color;

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
        return gradient.to_string ();
    }
}