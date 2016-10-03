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

            if (value) make_gradient ();
        }
    }

    // 0 == main, N = Gradient Color
    private int color_selector = 0;

    private Gtk.Popover popover;
    private Gtk.Grid colors_grid;
    private Gtk.Revealer gradient_revealer;
    private Gtk.Button custom_button;

    private ColorSurface preview;
    private ColorButton color1;
    private ColorButton color2;

    public ColorPicker () {
        base ("white");

        colors_grid = new Gtk.Grid ();
        colors_grid.margin = 6;

        generate_colors ();

        custom_button = new Gtk.Button.with_label (_("Custom Color"));
        colors_grid.attach (custom_button, 0, 8, 4, 1);

        gradient_revealer = new Gtk.Revealer ();

        var preview_label = new Gtk.Label (_("Preview:"));
        var color1_label = new Gtk.Label (_("Color 1:"));
        var color2_label = new Gtk.Label (_("Color 2:"));

        preview_label.get_style_context ().add_class ("h4");
        color1_label.get_style_context ().add_class ("h4");
        color2_label.get_style_context ().add_class ("h4");

        preview_label.halign = Gtk.Align.START;
        color1_label.halign = Gtk.Align.END;
        color2_label.halign = Gtk.Align.END;

        preview_label.margin_left = 6;
        color1_label.margin_right = 6;
        color2_label.margin_right = 6;

        color1 = new ColorButton ("red");
        color2 = new ColorButton ("orange");

        color1.clicked.connect (() => {color_selector = 1;});
        color2.clicked.connect (() => {color_selector = 2;});

        var gradient_grid = new Gtk.Grid ();

        preview = new ColorSurface ("");
        preview.set_size_request (100,100);
        gradient_grid.attach (preview_label, 0, 0, 3, 1);
        gradient_grid.attach (preview,       1, 1, 2, 2);
        gradient_grid.attach (color1_label,  0, 3, 2, 1);
        gradient_grid.attach (color1,        2, 3, 2, 1);
        gradient_grid.attach (color2_label,  0, 4, 2, 1);
        gradient_grid.attach (color2,        2, 4, 1, 1);

        gradient_revealer.add (gradient_grid);

        colors_grid.attach (gradient_revealer, 4, 0, 1, 8);

        var popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.add (colors_grid);

        this.clicked.connect (() => {
            popover.show_all ();
        });

        gradient = false;
    }

    public void make_gradient () {
        color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (color1.color, color2.color);
        preview.color = color;
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
        attach_color ("#EEE", 3, 0);
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

        color_button.margin_right = 3;

        if (y % 4 == 3) {
            color_button.margin_bottom = 3;
        }

        colors_grid.attach (color_button, x, y, 1, 1);

        color_button.clicked.connect (() => {
            if (this.color_selector == 0) {
                this.color = color;
                color_picked (color);
            } else if (this.color_selector == 1) {
                color1.color = color;
                make_gradient ();
            } else {
                color2.color = color;
                make_gradient ();
            }
        });
    }

    protected class ColorButton : Gtk.Button {
        private ColorSurface surface;

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
        private string color_;

        public string color {
            get {
                return color_;
            } set {
                color_ = value;
                style ();
            }
        }

        public ColorSurface (string color) {
            Object (color:color);
            get_style_context ().add_class ("colored");
            set_size_request (24,24);
            style ();
        }

        private void style () {
            var provider = new Gtk.CssProvider ();
            var context = get_style_context ();

            var colored_css = STYLE_CSS.printf (color_);
            provider.load_from_data (colored_css, colored_css.length);

            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        private const string STYLE_CSS = """
            .colored {
                background: %s;
            }
        """;
    }
}
