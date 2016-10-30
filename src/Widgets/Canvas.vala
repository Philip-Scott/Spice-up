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
    public signal void next_slide ();

    private const int SNAP_LIMIT = int.MAX - 1;

    public signal void configuration_changed ();
    public double current_ratio = 1.0f;

    public int current_allocated_width = 0;
    public int current_allocated_height = 0;
    private int default_x_margin = 0;
    private int default_y_margin = 0;

    public CanvasGrid grid;

    // Serializable items
    public Json.Object? save_data = null;
    public string background_color {get; set; default = "#383E41"; }
    public string background_pattern {get; set; default = ""; }

    public bool editable = true;

    const string CANVAS_CSS = """
        .view {
            background: %s;
        }
    """;

    public Canvas (Json.Object? save_data = null) {
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        this.save_data = save_data;

        grid = new CanvasGrid (this);
        set_size_request (500, 380);

        get_style_context ().add_class ("canvas");
        add (grid);

        calculate_ratio ();
        load_data ();
        style ();
    }

    public Canvas.preview (Json.Object? save_data = null) {
        this.save_data = save_data;

        editable = false;
        grid = new CanvasGrid (this);
        add (grid);
        set_size_request (200, 154);
        expand = false;

        get_style_context ().add_class ("canvas");

        load_data ();
        calculate_ratio ();
        style ();
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
        stderr.printf ("Configuration changed signal\n");
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

    public CanvasItem add_item (CanvasItem item, bool loading = false) {
        var canvas_item = item;

        current_allocated_width = 0;
        current_allocated_height = 0;

        add_overlay (canvas_item);

        var context = canvas_item.get_style_context ();
        context.add_class ("colored");

        canvas_item.show_all ();
        var old_delta_x = canvas_item.delta_x;
        var old_delta_y = canvas_item.delta_y;
        canvas_item.delta_x = 0;
        canvas_item.delta_y = 0;
        canvas_item.move_display (old_delta_x, old_delta_y);

        if (editable) {
            canvas_item.configuration_changed.connect (() => {
                check_configuration_changed ();
            });

            canvas_item.check_position.connect (() => {
                check_intersects (canvas_item);
            });

            canvas_item.clicked.connect (() => {
                unselect_all ();
                item_clicked (canvas_item);
            });

            canvas_item.move_display.connect ((delta_x, delta_y) => {
                if (window.is_fullscreen) return;

                var action = new Spice.Services.HistoryManager.HistoryAction<CanvasItem, Gdk.Rectangle?>.item_moved (canvas_item);
                Spice.Services.HistoryManager.get_instance ().add_undoable_action (action, true);

                int x, y, width, height;
                canvas_item.get_geometry (out x, out y, out width, out height);
                canvas_item.set_geometry ((int)(delta_x / current_ratio) + x, (int)(delta_y / current_ratio) + y, width, height);
                canvas_item.queue_resize_no_redraw ();
            });

            if (!loading) {
                canvas_item.visible = false;
                var action = new Spice.Services.HistoryManager.HistoryAction<CanvasItem,bool>.item_changed (canvas_item, "visible");
                Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
                canvas_item.visible = true;
            }
        }

        calculate_ratio ();
        return canvas_item;
    }

    public void unselect_all () {
        foreach (var item in get_children ()) {
            if (item is CanvasItem) {
                ((CanvasItem) item).unselect ();
            }
        }

        configuration_changed ();
    }

    public void clear_all () {
        foreach (var item in get_children ()) {
            if (item is CanvasItem) {
                ((CanvasItem) item).unselect ();
                ((CanvasItem) item).destroy ();
            }
        }
        configuration_changed ();
    }

    public void move_up (CanvasItem item_) {
        int index = 0;
        foreach (var item in get_children ()) {
            if (item == item_) break;
            index++;
        }

        reorder_overlay (item_, index + 1);
    }

    public void move_down (CanvasItem item_) {
        int index = 0;
        foreach (var item in get_children ()) {
            if (item == item_) break;
            index++;
        }

        if (index - 2 > -1) {
            reorder_overlay (item_, index - 2);
        }
    }

    /* Commented until used
    public void move_top (CanvasItem item) {
        reorder_overlay (item, -1);
    }

    public void move_bottom (CanvasItem item) {
        reorder_overlay (item, 0);
    }
    */

    public void check_intersects (CanvasItem source_display_widget) {
        source_display_widget.queue_resize_no_redraw ();
    }

    public override bool button_press_event (Gdk.EventButton event) {
        if (!editable) return false;

        if (window.is_fullscreen) {
            next_slide ();
        } else {
            unselect_all ();
            item_clicked (null);
        }

        return true;
    }

    public void load_data () {
        if (save_data == null) return;

        var background_color_ = save_data.get_string_member ("background-color");
        if (background_color != null) {
            background_color = background_color_;
        }

        var background_pattern_ = save_data.get_string_member ("background-pattern");
        if (background_pattern_ != null) {
            background_pattern = background_pattern_;
        }
    }

    public string serialise () {
        return """"background-color":"%s", "background-pattern":"%s" """.printf (background_color, background_pattern);
    }

    public new void style () {
        Utils.set_style (grid, CANVAS_CSS.printf (background_color));

        grid.style (background_pattern);
        configuration_changed ();
    }

    public Granite.Drawing.BufferSurface surface;
    public override bool draw (Cairo.Context cr) {
        base.draw (cr);

        surface = new Granite.Drawing.BufferSurface (this.current_allocated_width, this.current_allocated_height);
        base.draw (surface.context);

        //buffer.surface.write_to_png ("/home/felipe/pngtest.png");

        return true;
    }

    protected class CanvasGrid : Gtk.EventBox {
        Canvas canvas;

        Gtk.Grid grid;

        const string PATTERN_CSS = """
            .pattern {
                box-shadow: inset 0 0 0 2px alpha (#fff, 0.05);
                background-image: url("%s");
                border-radius: 6px;
            }
        """;

        const string NO_PATTERN_CSS = """
            .pattern {
                background-image: none;
            }
        """;

        protected CanvasGrid (Canvas canvas) {
            events |= Gdk.EventMask.BUTTON_PRESS_MASK;
            this.canvas = canvas;

            grid = new Gtk.Grid ();
            this.add (grid);
            grid.get_style_context ().add_class ("pattern");

            get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
            get_style_context ().add_class ("canvas");

            expand = true;
        }

        public override bool button_press_event (Gdk.EventButton event) {
            if (!canvas.editable) return false;

            if (window.is_fullscreen) {
                canvas.next_slide ();
            } else {
                canvas.item_clicked (null);
                canvas.unselect_all ();
            }

            return true;
        }

        public new void style (string pattern) {
            if (pattern != "") {
                Utils.set_style (grid, PATTERN_CSS.printf (pattern));
            } else {
                Utils.set_style (grid, NO_PATTERN_CSS);
            }
        }
    }
}
