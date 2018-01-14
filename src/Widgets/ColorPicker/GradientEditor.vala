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
    public signal void updated ();
    public signal void color_selected (int index, string color);

    public string gradient_color {
        get {
            return _gradient_color;
        } set {
            _gradient_color = value;
            parse_gradient (value);
        }
    }

    public Gradient gradient { get; private set; }

    private string _gradient_color;

    private unowned ColorPicker color_picker;
    private GradientMaker editor;
    private Gtk.Scale direction;

    private Gtk.Button add_step;
    private Gtk.Button remove_step;

    public GradientEditor (ColorPicker _color_picker) {
        gradient = new Gradient ();
        color_picker = _color_picker;
        make_gradient_view ();
    }

    private void make_gradient_view () {
        margin_top = 6;

        var gradient_grid = new Gtk.Grid ();
        gradient_grid.column_homogeneous = false;
        gradient_grid.row_homogeneous = false;
        gradient_grid.column_spacing = 16;
        gradient_grid.row_spacing = 6;
        gradient_grid.margin_start = 6;

        editor = new GradientMaker ();

        direction = new Gtk.Scale.with_range (Gtk.Orientation.VERTICAL, 180, 540, 1);
        direction.set_tooltip_text (_("Gradient Direction"));
        direction.vexpand = true;
        direction.draw_value = false;

        direction.add_mark (180, Gtk.PositionType.RIGHT, "");
        direction.add_mark (270, Gtk.PositionType.RIGHT, "");
        direction.add_mark (360, Gtk.PositionType.RIGHT, "");
        direction.add_mark (450, Gtk.PositionType.RIGHT, "");
        direction.add_mark (540, Gtk.PositionType.RIGHT, "");

        direction.value_changed.connect (() => {
            gradient.direction = "%ddeg".printf ((int) direction.get_value ());
            updated ();
        });

        var steps_grid = new Gtk.Grid ();
        steps_grid.get_style_context ().add_class ("linked");

        add_step = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_step.hexpand = true;

        remove_step = new Gtk.Button.from_icon_name ("list-remove-symbolic", Gtk.IconSize.MENU);
        remove_step.hexpand = true;

        add_step.clicked.connect (() => {
            string color = "#df0000";
            int percent = 50;

            if (color_picker.selected_color > 0) {
                var last = gradient.get_color (color_picker.selected_color - 1);
                color = last.color;

                var last_percent = int.parse (last.percent.replace ("%", ""));
                percent = last_percent < 50 ? last_percent + 25 : last_percent - 25;
                print (@"$percent");
            }

            gradient.steps.append (new Gradient.GradientStep (color, @"$percent%"));
            parse_gradient (gradient.to_string (false), true);
            updated ();
        });

        remove_step.clicked.connect (() => {
            if (color_picker.selected_color > 0) {
                var last = gradient.get_color (color_picker.selected_color - 1);
                gradient.steps.remove (last);

                parse_gradient (gradient.to_string (false), true);
                updated ();
            }
        });

        steps_grid.add (add_step);
        steps_grid.add (remove_step);

        gradient_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 0, 0, 1, 2);
        gradient_grid.attach (editor, 1, 0, 1, 1);
        gradient_grid.attach (direction, 2, 0, 1, 1);
        gradient_grid.attach (steps_grid, 1, 1, 2, 1);

        add (gradient_grid);
    }

    public void set_color (int step, string color) {
        gradient.get_color (step - 1).color = color;
    }

    public void parse_gradient (string color, bool force = false) {
        if (!force && make_gradient () == color) return;

        gradient.parse (color);
        editor.css_style (color);
        editor.clear_all ();

        int step_count = 0;
        gradient.steps.foreach ((item) => {
            step_count++;
            var nub = new GradientNub (this, item, editor);
            nub.clicked.connect (() => {
                var index = gradient.steps.index (nub.step);
                color_selected (index + 1, nub.color);
            });

            editor.add_overlay (nub);
        });

        remove_step.sensitive = step_count > 2;

        editor.show_all ();

        if (color.contains ("to bottom")) {
            direction.set_value (180);
        } else if (color.contains ("to right")) {
            direction.set_value (450);
        } else {
            direction.set_value (double.parse (gradient.direction));
        }

        if (step_count < color_picker.selected_color) {
            color_picker.selected_color = 1;
        }
    }

    public string make_gradient () {
        editor.css_style (gradient.to_string (true));
        return gradient.to_string (false);
    }

    private class GradientNub : ColorButton {
        public unowned Gradient.GradientStep step { get; private set; }
        public unowned GradientMaker maker;
        public unowned GradientEditor editor;

        public int delta_y { get; set; default = 0; }
        protected double start_y = 0;
        protected double start_value = 0;
        private bool holding = false;

        public GradientNub (GradientEditor editor, Gradient.GradientStep step, GradientMaker maker) {
            Object (color: step.color);

            get_style_context ().add_class ("circular");
            get_style_context ().add_class ("gradient");
            halign = Gtk.Align.START;
            valign = Gtk.Align.START;

            this.step = step;
            this.maker = maker;
            this.editor = editor;

            set_size (16);

            step.notify["color"].connect (() => {
                color = step.color;
            });

            step.notify["percent"].connect (() => {
                queue_resize_no_redraw ();
            });
        }

        public override bool button_press_event (Gdk.EventButton event) {
            clicked ();
            start_y = event.y_root;
            start_value = double.parse (step.percent.replace ("%", ""));
            holding = true;
            return false;
        }

        public override bool motion_notify_event (Gdk.EventMotion event) {
            if (!holding) return false;

            var percent = (int) (start_value + (event.y_root - start_y) / (parent.get_allocated_height () - get_allocated_height ()) * 100);
            step.percent = @"$(percent.clamp (0, 100))%";
            queue_resize_no_redraw ();
            editor.updated ();
            return false;
        }

        public override bool button_release_event (Gdk.EventButton event) {
            holding = false;
            return false;
        }
    }

    private class GradientMaker : Gtk.Overlay {
        private Gtk.Widget grid;

        construct {
            vexpand = true;
            halign = Gtk.Align.START;
            width_request = 32;
            grid = new Gtk.EventBox ();
            add (grid);
        }

        public void clear_all () {
            foreach (var item in get_children ()) {
                if (item is GradientNub)
                    item.destroy ();
            }
        }

        public override bool get_child_position (Gtk.Widget widget, out Gdk.Rectangle allocation) {
            allocation = Gdk.Rectangle ();
            var height = get_allocated_height ();

            if (widget is GradientNub) {
                var nub = (GradientNub) widget;
                var percent = double.parse (nub.step.percent.replace ("%", "")) / 100.0;

                int w, h;
                widget.get_preferred_width (out w, null);
                widget.get_preferred_height (out h, null);
                allocation.width = w;
                allocation.height = h;
                allocation.x = 3;
                allocation.y = (int) ((height - h) * percent);
                return true;
            }

            return false;
        }

        public void css_style (string style) {
            if (style.contains ("gradient") && style.contains (",")) {
                Utils.set_style (grid, STYLE.printf (style));
            }
        }

        private const string STYLE = """
            * {
                background-image: %s;
                border-radius: 20px;
                border: 1.4px solid rgba(0,0,0,0.2);
            }
        """;
    }
}