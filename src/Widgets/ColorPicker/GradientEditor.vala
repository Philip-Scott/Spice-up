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
    public Gtk.ComboBoxText gradient_type;

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
    private GradientMaker editor;

    public GradientEditor (ColorPicker _color_picker) {
        gradient = new Gradient ();
        color_picker = _color_picker;
        make_gradient_view ();
    }

    private void make_gradient_view () {
        margin_top = 6;

        var gradient_grid = new Gtk.Grid ();
        gradient_grid.row_homogeneous = false;
        gradient_grid.row_spacing = 6;
        gradient_grid.margin_start = 6;

        editor = new GradientMaker ();

        gradient_type = new Gtk.ComboBoxText ();
        gradient_type.margin = 3;
        gradient_type.expand = false;
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

        gradient_grid.attach (editor, 0, 0, 1, 1);
        gradient_grid.attach (gradient_type, 0, 1, 2, 1);

        add (gradient_grid);
    }

    public void set_color (int step, string color) {
        gradient.get_color (step - 1).color = color;
    }

    public void parse_gradient (string color) {
        if (make_gradient () == color) return;

        gradient.parse (color);
        editor.css_style (color);
        editor.clear_all ();

        gradient.steps.foreach ((item) => {
            var nub = new GradientNub (this, item, editor);
            nub.clicked.connect (() => {
                var index = gradient.steps.index (nub.step);
                color_selected (index + 1, nub.color);
            });

            editor.add_overlay (nub);
        });

        editor.show_all ();

        if (color.contains ("to bottom")) {
            gradient_type.set_active_id ("to bottom");
        } else if (color.contains ("to right")) {
            gradient_type.set_active_id ("to right");
        }
    }

    public string make_gradient () {
        editor.css_style (gradient.to_string (true));
        return gradient.to_string (false);;
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
            if (style.contains (",")) {
                Utils.set_style (grid, STYLE.printf (style));
            }
        }

        private const string STYLE = """
            * {
                background-image: %s;
                border-radius: 20px;
                border: 1.4px solid rgba(0,0,0,0.5);
            }
        """;
    }
}