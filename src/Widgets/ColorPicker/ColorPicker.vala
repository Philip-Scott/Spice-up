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

public class Spice.ColorPicker : ColorButton {
    public static Regex color_regex;
    public signal void color_picked (string color);

    public bool gradient {
        get {
            return gradient_revealer.reveal_child;
        }

        set {
            gradient_button.active = value;
            gradient_button.visible = value;
            gradient_button.no_show_all = !value;

            gradient_revealer.reveal_child = value;
            gradient_revealer.visible = value;
            gradient_revealer.no_show_all = !value;

            color_selector = value ? 3 : 0;
        }
    }

    public new string color {
        get {
            return _color;
        } set {
            ((ColorButton) this).color = value;
            preview.color = value;

            if (gradient) {
                parse_gradient (value);
            }
        }
    }

    public bool use_alpha { get; construct set; }

    // 0 == main, N = Gradient Color
    protected int color_selector = 0;
    private ulong color_chooser_signal;

    private Gtk.Stack colors_grid_stack;

    private Gtk.Popover popover;
    private Gtk.Grid colors_grid;
    private Gtk.Revealer gradient_revealer;
    private Gtk.ColorChooserWidget color_chooser;
    private Gtk.ToggleButton gradient_button;

    protected ColorButton preview;
    protected ColorButton color1;
    protected ColorButton color2;

    private Gtk.ComboBoxText gradient_type;

    public ColorPicker (bool use_alpha = true) {
        Object (color: "white", use_alpha: use_alpha);

        color_chooser.use_alpha = use_alpha;
    }

    static construct {
        try {
            color_regex = new Regex ("""(#.{3,6} )|rgba?\([0-9]{1,},[0-9]{1,},[0-9]{1,}(\)|,(0|1).?[0-9]{0,}\))""", 0);
        } catch (Error e) {
            error ("Regex failed: %s", e.message);
        }
    }

    construct {
        var main_grid = new Gtk.Grid ();
        main_grid.margin = 6;

        // Toolbar creation
        var button_toolbar = new Gtk.Grid ();
        button_toolbar.orientation = Gtk.Orientation.HORIZONTAL;

        var mode_button = new Granite.Widgets.ModeButton ();
        mode_button.append_icon ("view-grid-symbolic", Gtk.IconSize.MENU);
        mode_button.append_icon ("applications-graphics-symbolic", Gtk.IconSize.MENU);
        mode_button.selected = 0;

        mode_button.mode_changed.connect ((w) => {
            switch (mode_button.selected) {
                case 0:
                    colors_grid_stack.set_visible_child_name ("palete");
                    break;
                case 1:
                    colors_grid_stack.set_visible_child_name ("custom");
                    break;
            }
        });

        gradient_button = new Gtk.ToggleButton.with_label (_("Grad"));

        gradient_button.hexpand = true;
        gradient_button.halign = Gtk.Align.END;
        gradient_button.toggled.connect (() => {
            this.gradient_revealer.reveal_child = gradient_button.active;

            if (!gradient_button.active) {
                color_selector = 3;
            }
        });

        button_toolbar.add (mode_button);
        button_toolbar.add (gradient_button);

        colors_grid_stack = new Gtk.Stack ();
        colors_grid_stack.homogeneous = false;

        make_palette_view ();
        make_gradient_view ();
        make_custom_view ();

        main_grid.attach (button_toolbar, 0, 0, 5, 1);
        main_grid.attach (colors_grid_stack, 0, 1, 4, 8);
        main_grid.attach (gradient_revealer, 4, 1, 1, 8);

        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.add (main_grid);

        this.clicked.connect (() => {
            popover.show_all ();
        });

        gradient = false;
    }

    private void make_palette_view () {
        colors_grid = new Gtk.Grid ();
        colors_grid.margin = 6;
        colors_grid.get_style_context ().add_class ("card");

        generate_colors ();
        colors_grid_stack.add_named (colors_grid, "palete");
    }

    //TODO:
    // - import color picker icon & action
    private void make_custom_view () {
        color_chooser = new Gtk.ColorChooserWidget ();
        color_chooser.show_editor = true;

        var container = color_chooser as Gtk.Container;

        var color_chooser_grid = new Gtk.Grid ();
        color_chooser_grid.row_spacing = 6;
        color_chooser_grid.margin_top = 6;

        var hue_scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0.0, 1.0, 0.000001);
        hue_scale.expand = true;
        hue_scale.draw_value = false;

        foreach (var child in container.get_children ()) {
            if (child.visible) {
                var color_editor = (child as Gtk.Container).get_children ().nth_data (0);
                var overlay = (color_editor as Gtk.Container).get_children ().nth_data (0);
                var grid = (overlay as Gtk.Container).get_children ().nth_data (0) as Gtk.Grid;

                foreach (var picker_part in grid.get_children ()) {
                    switch (picker_part.name) {
                        case "GtkColorPlane":
                            grid.remove (picker_part);
                            color_chooser_grid.attach (picker_part, 0, 0, 3, 1);
                        break;
                        case "GtkColorScale":
                            var scale = picker_part as Gtk.Scale;
                            grid.remove (picker_part);
                            if (scale.orientation == Gtk.Orientation.VERTICAL) {
                                color_chooser_grid.attach (scale, 4, 0, 1, 1);
                            } else if (use_alpha) {
                                picker_part.expand = true;
                                color_chooser_grid.attach (picker_part, 1, 2, 1, 1);
                            }
                        break;
                        default:
                            print ("%s\n", picker_part.name);
                        break;
                    }
                }
            }
        }

        var color_picker_button = new Gtk.Button.from_icon_name ("system-search-symbolic", Gtk.IconSize.MENU);
        color_picker_button.margin_end = 6;
        color_picker_button.halign = Gtk.Align.START;

        color_chooser_grid.attach (color_picker_button, 0, 1, 1, 2);

        color_chooser_signal = color_chooser.notify["rgba"].connect (() => {
            set_color_smart (color_chooser.rgba.to_string (), false);
        });

        colors_grid_stack.add_named (color_chooser_grid, "custom");
    }

    private void make_gradient_view () {
        var gradient_grid = new Gtk.Grid ();
        gradient_grid.row_spacing = 6;
        gradient_grid.margin_left = 6;

        gradient_revealer = new Gtk.Revealer ();
        gradient_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        gradient_revealer.expand = true;

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
            color_selector = 1;
            set_color_chooser_color (color1.color);
        });

        color2.clicked.connect (() => {
            color_selector = 2;
            set_color_chooser_color (color2.color);
        });

        preview.clicked.connect (() => {
            color_selector = 3;
            set_color_chooser_color (preview.color);
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
            this.color = make_gradient ();
            color_picked (this.color);
        });

        gradient_grid.attach (preview_box,   1, 1, 2, 3);
        gradient_grid.attach (color1_label,  0, 4, 2, 1);
        gradient_grid.attach (color1,        2, 4, 2, 1);
        gradient_grid.attach (color2_label,  0, 5, 2, 1);
        gradient_grid.attach (color2,        2, 5, 1, 1);
        gradient_grid.attach (gradient_type, 0, 6, 3, 1);

        gradient_revealer.add (gradient_grid);
    }

    private void parse_gradient (string color) {
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

    public void generate_colors () {
        // red
        attach_color ("#ff8c82", 0, 0);
        attach_color ("#ed5353", 0, 1);
        attach_color ("#c6262e", 0, 2);
        attach_color ("#a10705", 0, 3);
        attach_color ("#7a0000", 0, 4);

        // orange
        attach_color ("#ffc27d", 1, 0);
        attach_color ("#ffa154", 1, 1);
        attach_color ("#f37329", 1, 2);
        attach_color ("#cc3b02", 1, 3);
        attach_color ("#a62100", 1, 4);

        // yellow
        attach_color ("#fff394", 2, 0);
        attach_color ("#ffe16b", 2, 1);
        attach_color ("#f9c440", 2, 2);
        attach_color ("#d48e15", 2, 3);
        attach_color ("#ad5f00", 2, 4);

        // green
        attach_color ("#d1ff82", 0, 5);
        attach_color ("#9bdb4d", 0, 6);
        attach_color ("#68b723", 0, 7);
        attach_color ("#3a9104", 0, 8);
        attach_color ("#206b00", 0, 9);

        // blue
        attach_color ("#8cd5ff", 1, 5);
        attach_color ("#64baff", 1, 6);
        attach_color ("#3689e6", 1, 7);
        attach_color ("#0d52bf", 1, 8);
        attach_color ("#002e99", 1, 9);

        // purple
        attach_color ("#e29ffc", 2, 5);
        attach_color ("#ad65d6", 2, 6);
        attach_color ("#7a36b1", 2, 7);
        attach_color ("#4c158a", 2, 8);
        attach_color ("#260063", 2, 9);

        // grayscale
        attach_color ("#dbe0f3", 3, 0);
        attach_color ("#c0c6de", 3, 1);
        attach_color ("#919caf", 3, 2);
        attach_color ("#68758e", 3, 3);
        attach_color ("#485a6c", 3, 4);

        attach_color ("#ffffff", 3, 5);
        attach_color ("#cbcbcb", 3, 6);
        attach_color ("#89898b", 3, 7);
        attach_color ("#505050", 3, 8);
        attach_color ("#000000", 3, 9);
    }

    private void attach_color (string color, int x, int y) {
        var color_button = new ColorButton (color);
        color_button.set_size_request (48,24);
        color_button.get_style_context ().add_class ("flat");
        color_button.can_focus = false;
        color_button.margin_right = 0;

        colors_grid.attach (color_button, x, y, 1, 1);

        color_button.clicked.connect (() => {
            set_color_smart (color, true);
        });
    }

    protected void set_color_smart (string color, bool from_button = false) {
        switch (this.color_selector) {
            case 0: // Single color
                this.color = color;
                break;
            case 1: // Color 1
                color1.color = color;
                this.color = make_gradient ();
                break;

            case 2: // Color 2
                color2.color = color;
                this.color = make_gradient ();
                break;

            case 3: // Both colors
                color1.color = color;
                color2.color = color;
                this.color = color;
                break;
        }

        if (from_button) {
            set_color_chooser_color (color);
        }

        color_picked (this.color);
    }

    private void set_color_chooser_color (string color) {
        SignalHandler.block (color_chooser, color_chooser_signal);

        Gdk.RGBA rgba = Gdk.RGBA ();
        rgba.parse (color);
        color_chooser.rgba = rgba;

        SignalHandler.unblock (color_chooser, color_chooser_signal);
    }
}
