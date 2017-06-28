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

    private double _current_ratio;
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

        default = 1.0f;
    }

    public int current_allocated_width = 0;
    public int current_allocated_height = 0;
    private int default_x_margin = 0;
    private int default_y_margin = 0;

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

    public override bool get_child_position (Gtk.Widget widget, out Gdk.Rectangle allocation) {
        if (current_allocated_width != get_allocated_width () || current_allocated_height != get_allocated_height ()) {
            calculate_ratio ();
        }

        if (widget is CanvasItem) {
            var display_widget = (CanvasItem) widget;

            var r = display_widget.rectangle;
            allocation = Gdk.Rectangle ();
            allocation.width = (int)(r.width * current_ratio);
            allocation.height = (int)(r.height * current_ratio);
            allocation.x = default_x_margin + (int)(r.x * current_ratio) + display_widget.delta_x;
            allocation.y = default_y_margin + (int)(r.y * current_ratio) + display_widget.delta_y;
            return true;
        }

        return false;
    }

    private void calculate_ratio () {
        int max_width = 1520, max_height = 1520;

        current_allocated_width = get_allocated_width ();
        current_allocated_height = get_allocated_height ();

        current_ratio = double.min ((double)(current_allocated_width - 24) / 1500.0, (double)(current_allocated_height - 24) / 1500.0);
        default_x_margin = (int) ((current_allocated_width - max_width * current_ratio) / 2);
        default_y_margin = (int) ((current_allocated_height - max_height * current_ratio) / 2);
    }

    public CanvasItem add_item (CanvasItem item, bool undoable_action = false) {
        var canvas_item = item;

        add_overlay (canvas_item);
        canvas_item.show_all ();

        canvas_item.check_position.connect (() => {
            check_intersects (canvas_item);
        });

        canvas_item.clicked.connect (() => {
            unselect_all ();
            item_clicked (canvas_item);
            request_draw_preview ();
        });

        canvas_item.move_item.connect ((delta_x, delta_y) => {
            if (window.is_fullscreen) return;

            var r = canvas_item.rectangle;
            canvas_item.rectangle = { (int)(delta_x / current_ratio) + r.x, (int)(delta_y / current_ratio) + r.y, r.width, r.height };
            canvas_item.queue_resize_no_redraw ();
            request_draw_preview ();
        });

        if (undoable_action) {
            canvas_item.visible = false;
            var action = new Spice.Services.HistoryManager.HistoryAction<CanvasItem,bool>.item_changed (canvas_item, "visible");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            canvas_item.visible = true;
        }

        return canvas_item;
    }

    public void unselect_all () {
        foreach (var item in get_children ()) {
            if (item is CanvasItem) {
                ((CanvasItem) item).unselect ();
            }
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
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action, true);
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
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action, true);
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
        if (window.is_fullscreen) {
            if (event.button == 1) {
                next_slide ();
            } else if (event.button == 3) {
                previous_slide ();
            }
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
        request_draw_preview ();
    }

    public Granite.Drawing.BufferSurface? surface = null;
    public override bool draw (Cairo.Context cr) {
        base.draw (cr);

        drawing_preview = true;
        surface = new Granite.Drawing.BufferSurface (this.current_allocated_width, this.current_allocated_height);
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
