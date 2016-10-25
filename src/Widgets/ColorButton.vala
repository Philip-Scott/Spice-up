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

public class Spice.ColorPicker : ColorButton {
    public signal void color_picked (string color);

    public bool gradient {
        get {
            return gradient_revealer.reveal_child;
        }

        set {
            gradient_revealer.reveal_child = value;
            gradient_revealer.visible = value;
            gradient_revealer.no_show_all = !value;

            color_selector = value ? 1 : 0;
        }
    }

    public new string color {
        get {
            return surface.color_;
        } set {
            preview.color = value;
            surface.color_ = value;
            surface.style ();

            if (gradient) {
                parse_gradient (value);
            }
        }
    }

    // 0 == main, N = Gradient Color
    private int color_selector = 0;

    private Gtk.Stack colors_grid_stack;

    private Gtk.Popover popover;
    private Gtk.Grid colors_grid;
    private Gtk.Revealer gradient_revealer;
    private Gtk.ToggleButton custom_button;
    private Gtk.ColorChooserWidget color_chooser;

    private ColorSurface preview;
    private ColorButton color1;
    private ColorButton color2;

    private EntryCombo gradient_type;

    public ColorPicker () {
        base ("white");

        colors_grid_stack = new Gtk.Stack ();
        colors_grid_stack.homogeneous = false;

        colors_grid = new Gtk.Grid ();
        var main_grid = new Gtk.Grid ();
        main_grid.margin = 6;

        generate_colors ();

        custom_button = new Gtk.ToggleButton.with_label (_("Custom Color"));
        custom_button.toggled.connect (() => {
            if (custom_button.active) {
                colors_grid_stack.set_visible_child_name ("custom");
            } else {
                colors_grid_stack.set_visible_child_name ("palete");
            }
        });

        main_grid.attach (custom_button, 0, 8, 4, 1);

        gradient_revealer = new Gtk.Revealer ();

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

        var gradient_grid = new Gtk.Grid ();
        gradient_grid.row_spacing = 6;

        preview = new ColorSurface ("");
        preview.set_size_request (100,100);

        gradient_type = new EntryCombo (true, false);
        gradient_type.vexpand = true;
        gradient_type.editable = false;
        gradient_type.max_length = 10;
        gradient_type.halign = Gtk.Align.END;
        gradient_type.valign = Gtk.Align.END;

        gradient_type.add_entry ("to bottom", "Vertical");
        gradient_type.add_entry ("to right", "Horizontal");
        //gradient_type.add_entry ("radial", "Radial"); TODO: Gtk doesn't support radial gradients just yet

        gradient_type.activated.connect ((data) => {
            this.color = make_gradient ();
            color_picked (this.color);
        });

        gradient_grid.attach (preview,       1, 1, 2, 2);
        gradient_grid.attach (color1_label,  0, 3, 2, 1);
        gradient_grid.attach (color1,        2, 3, 2, 1);
        gradient_grid.attach (color2_label,  0, 4, 2, 1);
        gradient_grid.attach (color2,        2, 4, 1, 1);
        gradient_grid.attach (gradient_type, 0, 5, 3, 1);

        gradient_revealer.add (gradient_grid);

        main_grid.attach (gradient_revealer, 4, 0, 1, 9);

        color_chooser = new Gtk.ColorChooserWidget ();
        color_chooser.show_editor = true;

        color_chooser.notify["rgba"].connect (() => {
            set_color_smart (rgb_to_hex (color_chooser.rgba.to_string ()));
        });

        color1.clicked.connect (() => {
            color_selector = 1;
            var rgba = Gdk.RGBA ();
            rgba.parse (color1.color);
            color_chooser.set_rgba (rgba);
        });

        color2.clicked.connect (() => {
            color_selector = 2;
            var rgba = Gdk.RGBA ();
            rgba.parse (color2.color);
            color_chooser.set_rgba (rgba);
        });

        main_grid.attach (colors_grid_stack, 0, 0, 4, 8);

        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.add (main_grid);

        colors_grid_stack.add_named (colors_grid, "palete");
        colors_grid_stack.add_named (color_chooser, "custom");

        this.clicked.connect (() => {
            colors_grid_stack.set_visible_child_name ("palete");
            custom_button.active = false;
            popover.show_all ();
        });

        gradient = false;
    }

    public void parse_gradient (string color) {
        string[] parts = color.split(","); //linear-gradient(to bottom | #CCC 0% | #666 100%)

        if (color.contains ("gradient")) {
            color1.color = parts[1].strip ().split (" ")[0];
            color2.color = parts[2].strip ().split (" ")[0];

            if (parts[0].contains ("to bottom")) {
                gradient_type.text = "to bottom";
            } else if (parts[0].contains ("to right")) {
                gradient_type.text = "to right";
            }
        } else {
            color1.color = color;
            color2.color = color;
        }
    }

    public string rgb_to_hex (string rgb) {
        Gdk.RGBA rgba = Gdk.RGBA ();
        rgba.parse (rgb);

        return "#%02x%02x%02x".printf ((int)(rgba.red * 255), (int)(rgba.green * 255), (int)(rgba.blue * 255));
    }

    public string make_gradient () {
        return "linear-gradient(%s, %s 0%, %s 100%)".printf (gradient_type.text, color1.color, color2.color);
    }

    public void generate_colors () {
        // Blues
        attach_color ("#51A7FE", 0, 0);
        attach_color ("#0364C2", 0, 1);
        attach_color ("#164F86", 0, 2);
        attach_color ("#022253", 0, 3);

        // Greens
        attach_color ("#70BF40", 1, 0);
        attach_color ("#01882A", 1, 1);
        attach_color ("#0C5D18", 1, 2);
        attach_color ("#043F07", 1, 3);

        // Yellow
        attach_color ("#F8D229", 2, 0);
        attach_color ("#DCBD24", 2, 1);
        attach_color ("#C6961A", 2, 2);
        attach_color ("#A27412", 2, 3);

        // Orange
        attach_color ("#F68F19", 0, 4);
        attach_color ("#E0690F", 0, 5);
        attach_color ("#BE5A0C", 0, 6);
        attach_color ("#944608", 0, 7);

        // Reds
        attach_color ("#EF5B5B", 1, 4);
        attach_color ("#CB2306", 1, 5);
        attach_color ("#861002", 1, 6);
        attach_color ("#550504", 1, 7);

        // Purple
        attach_color ("#B569E5", 2, 4);
        attach_color ("#773E9C", 2, 5);
        attach_color ("#5E337B", 2, 6);
        attach_color ("#3C1B50", 2, 7);

        // GrayScale
        attach_color ("#FFF", 3, 0);
        attach_color ("#CCC", 3, 1);
        attach_color ("#AAA", 3, 2);
        attach_color ("#888", 3, 3);

        attach_color ("#666", 3, 4);
        attach_color ("#444", 3, 5);
        attach_color ("#222", 3, 6);
        attach_color ("#000", 3, 7);
    }

    private void attach_color (string color, int x, int y) {
        var color_button = new ColorButton (color);
        color_button.set_size_request (48,24);
        color_button.get_style_context ().remove_class ("button");
        color_button.can_focus = false;
        color_button.margin_right = 3;

        if (y % 4 == 3) {
            color_button.margin_bottom = 3;
        }

        colors_grid.attach (color_button, x, y, 1, 1);

        color_button.clicked.connect (() => {
            set_color_smart (color, true);
        });
    }

    private void set_color_smart (string color, bool from_button = false) {
        if (this.color_selector == 0) {
            this.color = color;
        } else if (this.color_selector == 1) {
            color1.color = color;
            this.color = make_gradient ();
        } else {
            color2.color = color;
            this.color = make_gradient ();
        }

        if (from_button) {
            Gdk.RGBA rgba = Gdk.RGBA ();
            rgba.parse (color);
            color_chooser.rgba = rgba;
            color_picked (this.color);
        }

        //color_picked (this.color);
    }

    protected class ColorButton : Gtk.Button {
        protected ColorSurface surface;

        public string color {
            get {
                return surface.color;
            } set {
                surface.color = value;
            }
        }

        public ColorButton (string color) {
            surface = new ColorSurface (color);
            this.add (surface);
        }
    }

    protected class ColorSurface : Gtk.EventBox {
        public string color_ = "none";

        public string color {
            get {
                return color_;
            } set {
                if (value != "") {
                    color_ = value;
                    style ();
                }
            }
        }

        public ColorSurface (string color) {
            Object (color:color);
            get_style_context ().add_class ("colored");
            set_size_request (24,24);
            style ();
        }

        public new void style () {
            Utils.set_style (this, STYLE_CSS.printf (color_));
        }

        private const string STYLE_CSS = """
            .colored {
                background: %s;
            }
        """;
    }
}
