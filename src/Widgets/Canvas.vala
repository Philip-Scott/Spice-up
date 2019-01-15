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
    public signal void request_draw_preview ();
    public static bool drawing_preview = false;

    public signal void item_clicked (CanvasItem? item);
    public signal void ratio_changed (double ratio);
    public signal void next_slide ();
    public signal void previous_slide ();

    private double _current_ratio = 1.0f;
    public double current_ratio {
        get {
            return _current_ratio;
        }

        set {
            if (value != _current_ratio) {
                _current_ratio = value;
                ratio_changed (current_ratio);
            }
        }
    }

    public unowned Spice.Window window;

    public double current_allocated_width = 0;
    public double current_allocated_height = 0;
    private double default_x_margin = 0;
    private double default_y_margin = 0;

    public CanvasGrid grid;

    // Serializable items
    public Json.Object? save_data = null;
    public string background_color { get; set; default = "#383E41"; }
    public string background_pattern { get; set; default = ""; }

    const string CANVAS_CSS = """
        .view {
            background: %s;
        }
    """;

    public Canvas (Spice.Window window, Json.Object? save_data = null) {
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        this.window = window;
        this.save_data = save_data;

        grid = new CanvasGrid (this);
        set_size_request (500, 380);

        get_style_context ().add_class ("canvas");
        add (grid);

        // Hacky fix to prevent empty slides
        // from not rendering in the sidebar
        add_overlay (new Gtk.Label (""));

        calculate_ratio ();
        load_data ();
        style ();
    }

    public override bool get_child_position (Gtk.Widget widget, out Gdk.Rectangle allocation) {
        allocation = Gdk.Rectangle ();
        if (current_allocated_width != get_allocated_width () || current_allocated_height != get_allocated_height ()) {
            calculate_ratio ();
        }

        if (widget is CanvasItem) {
            var display_widget = (CanvasItem) widget;

            var r = display_widget.rectangle;
            int w, h;

            widget.get_preferred_width (out w, null);
            widget.get_preferred_height (out h, null);

            allocation.width = (int)(((double) r.width) * current_ratio + 0.5);
            allocation.height = (int)(((double) r.height) * current_ratio + 0.5);
            allocation.x = (int) (default_x_margin + (r.x * current_ratio + 0.5) + display_widget.delta_x);
            allocation.y = (int) (default_y_margin + (r.y * current_ratio + 0.5) + display_widget.delta_y);

            return true;
        }

        return false;
    }

    private void calculate_ratio () {
        double max_width = 1500.0, max_height = 1500.0;

        current_allocated_width = (double) get_allocated_width ();
        current_allocated_height = (double) get_allocated_height ();

        var ratio = ((double) (current_allocated_height)) / 1500.0;
        current_ratio = ratio - ratio * 0.016; // 24/1500 = 0.016; Legacy offset;

        default_x_margin = (((current_allocated_width - max_width * current_ratio) / 2.0) + 0.5);
        default_y_margin = (((current_allocated_height - max_height * current_ratio) / 2.0) + 0.5);
    }

    public CanvasItem add_item (CanvasItem item, bool undoable_action = false) {
        var canvas_item = item;

        add_overlay (canvas_item);
        canvas_item.show_all ();

        canvas_item.check_position.connect (canvas_item.queue_resize_no_redraw);

        canvas_item.clicked.connect (() => {
            unselect_all (false);
            item_clicked (canvas_item);
        });

        canvas_item.move_item.connect ((delta_x, delta_y) => {
            if (window.is_presenting) return;

            var r = canvas_item.rectangle;
            canvas_item.rectangle = { (int)(delta_x / current_ratio) + r.x, (int)(delta_y / current_ratio) + r.y, r.width, r.height };
            canvas_item.queue_resize_no_redraw ();
            request_draw_preview ();
        });

        if (undoable_action) {
            canvas_item.visible = false;
            var action = new Spice.Services.HistoryManager.HistoryAction<CanvasItem,bool>.item_changed (canvas_item, "visible");
            window.history_manager.add_undoable_action (action);
            canvas_item.visible = true;
        }

        request_draw_preview ();
        return canvas_item;
    }

    public void unselect_all (bool reset_item = true) {
        foreach (var item in get_children ()) {
            if (item is CanvasItem) {
                ((CanvasItem) item).unselect ();
            }
        }

        if (reset_item) {
            item_clicked (null);
        }

        request_draw_preview ();
    }

    public void clear_all () {
        foreach (var item in get_children ()) {
            if (item is CanvasItem) {
                ((CanvasItem) item).unselect ();
                ((CanvasItem) item).destroy ();
            }
        }
    }

    public void move_up (CanvasItem item_, bool add_undo_action = true) {
        int index = 0;
        foreach (var item in get_children ()) {
            if (item == item_) break;
            index++;
        }

        if (add_undo_action) {
            var action = new Spice.Services.HistoryManager.HistoryAction<CanvasItem, bool>.depth_changed (item_, this, true);
            window.history_manager.add_undoable_action (action, true);
        }

        reorder_overlay (item_, index + 1);
    }

    public void move_down (CanvasItem item_, bool add_undo_action = true) {
        int index = 0;
        foreach (var item in get_children ()) {
            if (item == item_) break;
            index++;
        }

        if (index - 2 > -1) {
            reorder_overlay (item_, index - 2);
        }

        if (add_undo_action) {
            var action = new Spice.Services.HistoryManager.HistoryAction<CanvasItem, bool>.depth_changed (item_, this, false);
            window.history_manager.add_undoable_action (action, true);
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

    public override bool button_press_event (Gdk.EventButton event) {
        if (window.is_presenting) {
            if (event.button == 1) {
                next_slide ();
            } else if (event.button == 3) {
                previous_slide ();
            }
        } else {
            unselect_all ();
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
        request_draw_preview ();
    }

    public Granite.Drawing.BufferSurface? surface = null;
    public override bool draw (Cairo.Context cr) {
        base.draw (cr);

        drawing_preview = true;
        surface = new Granite.Drawing.BufferSurface ((int) this.current_allocated_width, (int) this.current_allocated_height);
        base.draw (surface.context);
        drawing_preview = false;

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

        public CanvasGrid (Canvas canvas) {
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
            return canvas.button_press_event (event);
        }

        public new void style (string pattern) {
            if (pattern != "") {
                if (pattern.contains (Widgets.CanvasToolbar.PATTERNS_DIR) || File.new_for_path (pattern).query_exists ()) {
                    Utils.set_style (grid, PATTERN_CSS.printf (pattern));
                } else {
                    Utils.set_style (grid, NO_PATTERN_CSS);
                }
            } else {
                Utils.set_style (grid, NO_PATTERN_CSS);
            }
        }
    }
}
