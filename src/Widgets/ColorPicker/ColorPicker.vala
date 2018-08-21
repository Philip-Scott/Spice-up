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
    public signal void color_picked (string color);

    public bool gradient {
        get {
            return gradient_button.visible;
        }

        protected set {
            gradient_button.visible = value;
            gradient_button.no_show_all = !value;

            gradient_revealer.visible = value;
            gradient_revealer.no_show_all = !value;
            gradient_revealer.reveal_child = false;

            if (value && gradient_colors_grid == null) {
                mode_button.append (new Gtk.Image.from_resource ("/com/github/philip-scott/spice-up/gradient-palette-symbolic.svg"));
                make_gradient_palete ();
            }
        }
    }

    public new string color {
        get {
            return _color;
        } set {
            ((ColorButton) this).color = value;

            if (gradient) {
                gradient_editor.parse_gradient (value);
            }
        }
    }

    public bool use_alpha { get; construct set; }

    private ulong color_chooser_signal;

    private Gtk.Stack colors_grid_stack;

    private Gtk.Popover popover;
    private Gtk.Grid colors_grid;
    private Gtk.Grid gradient_colors_grid;
    protected Gtk.Revealer gradient_revealer;
    private Gtk.ColorChooserWidget color_chooser;
    private Gtk.ToggleButton gradient_button;
    private Granite.Widgets.ModeButton mode_button;

    protected GradientEditor gradient_editor;

    public ColorPicker (bool use_alpha = true) {
        Object (color: "white", use_alpha: use_alpha);
        color_chooser.use_alpha = use_alpha;
    }

    public ColorPicker.with_gradient (bool use_alpha = true) {
        Object (color: "white", use_alpha: use_alpha, gradient: true);
        color_chooser.use_alpha = use_alpha;
    }

    construct {
        var main_grid = new Gtk.Grid ();
        main_grid.margin = 6;

        // Toolbar creation
        var button_toolbar = new Gtk.Grid ();
        button_toolbar.orientation = Gtk.Orientation.HORIZONTAL;

        mode_button = new Granite.Widgets.ModeButton ();

        mode_button.mode_added.connect ((index, widget) => {
            switch (index) {
                case 0: widget.set_tooltip_text (_("Color Palette")); break;
                case 1: widget.set_tooltip_text (_("Custom Color")); break;
                case 2: widget.set_tooltip_text (_("Gradient Palette")); break;
            }
        });

        mode_button.append (new Gtk.Image.from_resource ("/com/github/philip-scott/spice-up/color-palette-symbolic.svg"));
        mode_button.append (new Gtk.Image.from_resource ("/com/github/philip-scott/spice-up/custom-color-symbolic.svg"));
        mode_button.selected = 0;

        mode_button.mode_changed.connect ((w) => {
            switch (mode_button.selected) {
                case 0:
                    colors_grid_stack.set_visible_child_name ("palete");
                    break;
                case 1:
                    colors_grid_stack.set_visible_child_name ("custom");
                    break;
                case 2:
                    colors_grid_stack.set_visible_child_name ("gradients");
                    break;
            }
        });

        gradient_button = new Gtk.ToggleButton ();
        gradient_button.add (new Gtk.Image.from_resource ("/com/github/philip-scott/spice-up/gradient-symbolic.svg"));
        gradient_button.set_tooltip_text (_("Gradient Editor"));
        gradient_button.active = false;
        gradient_button.hexpand = true;
        gradient_button.halign = Gtk.Align.END;
        gradient_button.toggled.connect (() => {
            this.gradient_revealer.reveal_child = gradient_button.active;
        });

        button_toolbar.add (mode_button);
        button_toolbar.add (gradient_button);

        colors_grid_stack = new Gtk.Stack ();
        colors_grid_stack.homogeneous = false;

        gradient_revealer = new Gtk.Revealer ();
        gradient_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        gradient_revealer.expand = true;

        gradient_editor = new GradientEditor (this);
        gradient_revealer.add (gradient_editor);

        gradient_editor.color_selected.connect ((index, color ) => {
            set_color_chooser_color (color);
        });

        gradient_editor.updated.connect (() => {
            color = gradient_editor.make_gradient ();
            color_picked (gradient_editor.make_gradient ());
        });

        make_palette_view ();
        make_custom_view ();

        main_grid.attach (button_toolbar, 0, 0, 5, 1);
        main_grid.attach (colors_grid_stack, 0, 1, 4, 8);
        main_grid.attach (gradient_revealer, 4, 1, 1, 8);

        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.add (main_grid);

        popover.key_press_event.connect ((source, key) => {
            // Ctrl + ? Events
            if (Gdk.ModifierType.CONTROL_MASK in key.state) {
                Gtk.Clipboard clipboard = Gtk.Clipboard.get (Gdk.Atom.intern_static_string ("SPICE_UP_COLOR"));
                switch (key.keyval) {
                    case 99: // C
                    case 120: // X
                        clipboard.set_text (color, -1);
                        return true;
                    case 118: // V
                        set_color_smart (clipboard.wait_for_text (), true, true);
                        return true;
                    case 65535: // Delete Key
                    case 65288: // Backspace
                        set_color_smart ("#FFF", true, true);
                        return true;
                }
            }
            return false;
        });

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
                            picker_part.height_request = 255;
                            picker_part.width_request = 255;
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
                    }
                }
            }
        }

        var color_picker_button = new Gtk.Button.from_icon_name ("color-select-symbolic", Gtk.IconSize.MENU);
        color_picker_button.set_tooltip_text (_("Pick Color"));
        color_picker_button.margin_end = 6;
        color_picker_button.halign = Gtk.Align.START;

        color_picker_button.clicked.connect (() => {
            var mouse_position = new PickerWindow ();
            mouse_position.show_all ();
            var previous = this.color_chooser.rgba;

            mouse_position.moved.connect ((t, color) => {
                var ext_color = (ExtRGBA) color;
                set_color_smart (ext_color.to_css_rgb_string (), true);
            });

            mouse_position.cancelled.connect (() => {
                mouse_position.close ();
                set_color_smart (previous.to_string (), true);
                mouse_position.destroy ();
            });

            mouse_position.picked.connect ((t, color) => {
                var ext_color = (ExtRGBA) color;
                set_color_smart (ext_color.to_css_rgb_string (), true);

                mouse_position.close ();
            });
        });

        color_chooser_grid.attach (color_picker_button, 0, 1, 1, 2);

        color_chooser_signal = color_chooser.notify["rgba"].connect (() => {
            set_color_smart (color_chooser.rgba.to_string (), false);
        });

        colors_grid_stack.add_named (color_chooser_grid, "custom");
    }

    public void generate_colors () {
        // red
        attach_color ("#ff8c82", 0, 0);
        attach_color ("#ed5353", 1, 0);
        attach_color ("#c6262e", 2, 0);
        attach_color ("#a10705", 3, 0);
        attach_color ("#7a0000", 4, 0);

        // orange
        attach_color ("#ffc27d", 5, 0);
        attach_color ("#ffa154", 6, 0);
        attach_color ("#f37329", 7, 0);
        attach_color ("#cc3b02", 8, 0);
        attach_color ("#a62100", 9, 0);

        // Cocoa
        attach_color ("#a3907c", 10, 0);
        attach_color ("#8a715e", 11, 0);
        attach_color ("#715344", 12, 0);
        attach_color ("#57392d", 13, 0);
        attach_color ("#3d211b", 14, 0);

        // Blacks
        attach_color ("#666666", 15, 0);
        attach_color ("#4d4d4d", 16, 0);
        attach_color ("#333333", 17, 0);
        attach_color ("#1a1a1a", 18, 0);
        attach_color ("#000000", 19, 0);


        // Bubblegum
        attach_color ("#fec2cf", 0, 1);
        attach_color ("#fe9ab8", 1, 1);
        attach_color ("#f46099", 2, 1);
        attach_color ("#e41b79", 3, 1);
        attach_color ("#c10f68", 4, 1);

        // yellow
        attach_color ("#fff394", 5, 1);
        attach_color ("#ffe16b", 6, 1);
        attach_color ("#f9c440", 7, 1);
        attach_color ("#d48e15", 8, 1);
        attach_color ("#ad5f00", 9, 1);

        // blue
        attach_color ("#8cd5ff", 10, 1);
        attach_color ("#64baff", 11, 1);
        attach_color ("#3689e6", 12, 1);
        attach_color ("#0d52bf", 13, 1);
        attach_color ("#002e99", 14, 1);

        // Slate
        attach_color ("#95a3ab", 15, 1);
        attach_color ("#667885", 16, 1);
        attach_color ("#485a6c", 17, 1);
        attach_color ("#273445", 18, 1);
        attach_color ("#0e141f", 19, 1);


        // purple
        attach_color ("#e29ffc", 0, 2);
        attach_color ("#ad65d6", 1, 2);
        attach_color ("#7a36b1", 2, 2);
        attach_color ("#4c158a", 3, 2);
        attach_color ("#260063", 4, 2);

        // green
        attach_color ("#d1ff82", 5, 2);
        attach_color ("#9bdb4d", 6, 2);
        attach_color ("#68b723", 7, 2);
        attach_color ("#3a9104", 8, 2);
        attach_color ("#206b00", 9, 2);

        // Mint
        attach_color ("#96fce5", 10, 2);
        attach_color ("#23fdd9", 11, 2);
        attach_color ("#00f4d4", 12, 2);
        attach_color ("#00d0bf", 13, 2);
        attach_color ("#00a69c", 14, 2);

        // grayscale
        attach_color ("#ffffff", 15, 2);
        attach_color ("#d4d4d4", 16, 2);
        attach_color ("#abacae", 17, 2);
        attach_color ("#7e8087", 18, 2);
        attach_color ("#555761", 19, 2);
    }

    private void attach_color (string color, int x, int y) {
        var color_button = new ColorButton (color);
        color_button.set_size (14, 84);
        color_button.get_style_context ().add_class ("flat");
        color_button.can_focus = true;
        color_button.margin_end = 0;

        colors_grid.attach (color_button, x, y, 1, 1);

        color_button.clicked.connect (() => {
            set_color_smart (color, true);
        });
    }

    private void make_gradient_palete () {
        gradient_colors_grid = new Gtk.Grid ();
        gradient_colors_grid.margin = 6;
        gradient_colors_grid.get_style_context ().add_class ("card");

        generate_gradient_colors ();
        colors_grid_stack.add_named (gradient_colors_grid, "gradients");
    }

    public void generate_gradient_colors () {
        attach_gradient ("linear-gradient(to right, #efefbb 0%, #d4d3dd 100%)", 0, 0);
        attach_gradient ("linear-gradient(to right, #43c6ac 0%, #f8ffae 100%)", 0, 1);
        attach_gradient ("linear-gradient(to right, #1fa2ff 0%, #12d8fa 50%, #a6ffcb 100%)", 0, 2);
        attach_gradient ("linear-gradient(to right, #70e1f5 0%, #ffd194 100%)", 0, 3);
        attach_gradient ("linear-gradient(to right, #ff0844 0%, #ffb199 100%)", 0, 4);

        attach_gradient ("linear-gradient(to right, #f0f2f0 0%, #000c40 100%)", 1, 0);
        attach_gradient ("linear-gradient(to right, #bbd2c5 0%, #536976 100%)", 1, 1);
        attach_gradient ("linear-gradient(to right, #3ab5b0 0%, #3D99BE 31%, #56317a 100%)", 1, 2);
        attach_gradient ("linear-gradient(to right, #f46b45 0%, #eea849 100%)", 1, 3);
        attach_gradient ("linear-gradient(to right, #F05F57 10%, #360940 100%)", 1, 4);
    }

    private void attach_gradient (string color, int x, int y) {
        var color_button = new ColorButton (color);
        color_button.set_size_request (96, 48);
        color_button.get_style_context ().add_class ("flat");
        color_button.can_focus = true;
        color_button.margin_end = 0;

        gradient_colors_grid.attach (color_button, x, y, 1, 1);

        color_button.clicked.connect (() => {
            set_color_smart (color, true, true);
        });
    }

    protected void set_color_smart (string color, bool from_button = false, bool overwite_gradient = false) {
        if (gradient_revealer.reveal_child) { // Gradient color changed
            gradient_editor.set_color (color, overwite_gradient);
            this.color = gradient_editor.make_gradient ();
        } else {
            gradient_editor.parse_gradient (color);
            if (gradient) {
                this.color = gradient_editor.make_gradient ();
            } else {
                var first_step = gradient_editor.gradient.get_color (0);
                this.color = first_step.color;
            }
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
