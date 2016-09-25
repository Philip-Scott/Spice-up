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

public class Spice.Canvas : Gtk.Overlay {
    public signal void item_clicked (CanvasItem? item);
    public signal void ratio_changed (double ratio);

    private const int SNAP_LIMIT = int.MAX - 1;

    public signal void configuration_changed ();
    public double current_ratio = 1.0f;

    private int current_allocated_width = 0;
    private int current_allocated_height = 0;
    private int default_x_margin = 0;
    private int default_y_margin = 0;

    public bool editable = true;

    private const string TESTING_DATA = """
{"items": [ {
              "x": -313,
              "y": -76,
              "w": 2203,
              "h": 1731,

           "type": "color",
           "background_color": "rgb(114,159,207)"

              }
       , {
              "x": -354,
              "y": 970,
              "w": 1925,
              "h": 122,

           "type": "color",
           "background_color": "rgb(252,233,79)"

              }
       , {
              "x": -280,
              "y": 458,
              "w": 1897,
              "h": 336,

           "type":"text",
           "text": "New Presentation",
           "font": "Raleway Medium 10",
           "color": "rgb(255,255,255)",
           "font-size": 42

              }
       , {
              "x": -339,
              "y": 552,
              "w": 902,
              "h": 500,

           "type":"text",
           "text": "By Felipe Escoto",
           "font": "Open Sans",
           "color": "rgb(255,255,255)",
           "font-size": 18

              }
       ]}
    """;

    public Canvas () {
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;

        var grid = new CanvasGrid (this);
        set_size_request (500, 380);

        get_style_context ().add_class ("canvas");

        load_data (TESTING_DATA);
        add (grid);

        calculate_ratio ();
    }

    public Canvas.preview () {
        editable = false;
        var grid = new CanvasGrid (this);
        set_size_request (100, 100);
        expand = false;

        get_style_context ().add_class ("canvas");

        load_data (TESTING_DATA);
        calculate_ratio ();
    }

    public void load_data (string data) {
        var parser = new Json.Parser ();
        parser.load_from_data (data);

        var root_object = parser.get_root ().get_object ();
        var items = root_object.get_array_member ("items");

        foreach (var raw in items.get_elements ()) {
            var item = raw.get_object ();

            string type = item.get_string_member ("type");

            switch (type) {
                case "text":
                    var canvas_item = new TextItem (this, item);
                    add_output (canvas_item);
                break;
                case "color":
                    var canvas_item = new ColorItem (this, item);
                    add_output (canvas_item);
                break;
            }
        }
    }

    public string serialise () {
        string data = "";

        foreach (var widget in get_children ()) {
            if (widget is CanvasItem) {
                CanvasItem item = (CanvasItem) widget;

                data = data + (data != "" ? "," + item.serialise () : item.serialise ());
            }
        }

        return """{"items": [%s]}""".printf (data);
    }

    public override bool get_child_position (Gtk.Widget widget, out Gdk.Rectangle allocation) {
        if (current_allocated_width != get_allocated_width () || current_allocated_height != get_allocated_height ()) {
            calculate_ratio ();
        }

        if (widget is CanvasItem) {
            var display_widget = (CanvasItem) widget;

            int x, y, width, height;
            display_widget.get_geometry (out x, out y, out width, out height);
            allocation = Gdk.Rectangle ();
            allocation.width = (int)(width * current_ratio);
            allocation.height = (int)(height * current_ratio);
            allocation.x = default_x_margin + (int)(x * current_ratio) + display_widget.delta_x;
            allocation.y = default_y_margin + (int)(y * current_ratio) + display_widget.delta_y;
            return true;
        }

        return false;
    }

    private void check_configuration_changed () {
        configuration_changed ();
    }

    private void calculate_ratio () {
        int added_width = 0;
        int added_height = 0;
        int max_width = 0;
        int max_height = 0;

        int x = 20, y = 20, width = 1500, height = 1500;
        added_width += width;
        added_height += height;
        max_width = int.max (max_width, x + width);
        max_height = int.max (max_height, y + height);

        current_allocated_width = get_allocated_width ();
        current_allocated_height = get_allocated_height ();
        current_ratio = double.min ((double)(get_allocated_width () -24) / (double) added_width, (double)(get_allocated_height ()-24) / (double) added_height);
        default_x_margin = (int) ((get_allocated_width () - max_width*current_ratio)/2);
        default_y_margin = (int) ((get_allocated_height () - max_height*current_ratio)/2);

        ratio_changed (current_ratio);
    }

    public CanvasItem add_output (CanvasItem item) {
        var canvas_item = item;

        current_allocated_width = 0;
        current_allocated_height = 0;

        add_overlay (canvas_item);

        try {
            var context = canvas_item.get_style_context ();
            context.add_class ("colored");
        } catch (GLib.Error e) {
            critical (e.message);
        }

        if (editable) {
            canvas_item.configuration_changed.connect (() => check_configuration_changed ());
            canvas_item.check_position.connect (() => check_intersects (canvas_item));
            canvas_item.clicked.connect (() => {
                unselect_all ();
                item_clicked (canvas_item);
            });

            canvas_item.move_display.connect ((delta_x, delta_y) => {
                if (Spice.Window.is_fullscreen) return;

                int x, y, width, height;
                canvas_item.get_geometry (out x, out y, out width, out height);
                canvas_item.set_geometry ((int)(delta_x / current_ratio) + x, (int)(delta_y / current_ratio) + y, width, height);
                canvas_item.queue_resize_no_redraw ();
            });

        }

        canvas_item.show_all ();
        var old_delta_x = canvas_item.delta_x;
        var old_delta_y = canvas_item.delta_y;
        canvas_item.delta_x = 0;
        canvas_item.delta_y = 0;
        canvas_item.move_display (old_delta_x, old_delta_y);

        calculate_ratio ();

        return canvas_item;
    }

    public void unselect_all () {
        foreach (var item in get_children ()) {
            if (item is CanvasItem) {
                ((CanvasItem) item).unselect ();
            }
        }
    }

    public void check_intersects (CanvasItem source_display_widget) {
        source_display_widget.queue_resize_no_redraw ();
    }

    public override bool button_press_event (Gdk.EventButton event) {
        if (!editable) return false;
        stderr.printf ("Pressed item indirectly\n");

        if (Spice.Window.is_fullscreen) {
            // Next slide
        } else {
            item_clicked (null);
            unselect_all ();
        }

        return true;
    }

    protected class CanvasGrid : Gtk.EventBox {
        Canvas canvas;

        protected CanvasGrid (Canvas canvas) {
            events |= Gdk.EventMask.BUTTON_PRESS_MASK;
            this.canvas = canvas;

            get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

            expand = true;
        }

        public override bool button_press_event (Gdk.EventButton event) {
        //if (!editable) return false;
            stderr.printf ("Pressed canvas\n");

            if (Spice.Window.is_fullscreen) {
                // Next slide
            } else {
                canvas.item_clicked (null);
                canvas.unselect_all ();
            }

            return true;
        }
    }
}
