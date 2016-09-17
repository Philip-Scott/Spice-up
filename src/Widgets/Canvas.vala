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
    public signal void item_clicked (CanvasItem item);

    private const int SNAP_LIMIT = int.MAX - 1;

    public signal void configuration_changed ();

    public static double current_ratio = 1.0f;
    private int current_allocated_width = 0;
    private int current_allocated_height = 0;
    private int default_x_margin = 0;
    private int default_y_margin = 0;
    public int active_displays { get; set; default = 0; }

    private const string TESTING_DATA = """
        {
	"items": [
	{
	    "type": "color",
	    "x": 100,
	    "y": 50,
	    "w": 830,
	    "h": 500,
	    "background_color": "#36f"
    },{
		"type":"text",
		"text":"Spice-up",
		"x": 100,
		"y": 50,
		"w": 230,
		"h": 50
	}]
}
    """;

    public Canvas () {
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
    
        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        grid.get_style_context ().add_class ("canvas");
        grid.expand = true;

        set_size_request (500, 380);

        load_data (TESTING_DATA);

        add (grid);

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
                    var canvas_item = new TextItem ();
                    add_output (canvas_item);
                break;
                case "color":
                    var canvas_item = new ColorItem (item);
                    add_output (canvas_item);
                break;
            }
        }
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

        canvas_item.show_all ();
        canvas_item.configuration_changed.connect (() => check_configuration_changed ());
        canvas_item.check_position.connect (() => check_intersects (canvas_item));

        canvas_item.clicked.connect (() => {
            unselect_all ();
            item_clicked (canvas_item);
        });

        canvas_item.show_all ();

        canvas_item.move_display.connect ((delta_x, delta_y) => {
            if (Spice.Window.is_fullscreen) return;

            int x, y, width, height;
            canvas_item.get_geometry (out x, out y, out width, out height);
            canvas_item.set_geometry ((int)(delta_x / current_ratio) + x, (int)(delta_y / current_ratio) + y, width, height);
            canvas_item.queue_resize_no_redraw ();
        });

        var old_delta_x = canvas_item.delta_x;
        var old_delta_y = canvas_item.delta_y;
        canvas_item.delta_x = 0;
        canvas_item.delta_y = 0;
        canvas_item.move_display (old_delta_x, old_delta_y);

        calculate_ratio ();

        return canvas_item;
    }
    
    private void unselect_all () {
        foreach (var item in get_children ()) {
            if (item is CanvasItem)
                ((CanvasItem) item).unselect ();
        }
        
    }

    public void check_intersects (CanvasItem source_display_widget) {
        source_display_widget.queue_resize_no_redraw ();
    }
}
