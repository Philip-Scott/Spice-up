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

public abstract class Spice.CanvasItem : Gtk.EventBox {
    private const int MIN_SIZE = 40;

    public signal void clicked ();
    protected signal void un_select ();

    public signal void set_as_primary ();
    public signal void move_item (int delta_x, int delta_y);
    public signal void check_position ();
    public signal void active_changed ();

    public int delta_x { get; set; default = 0; }
    public int delta_y { get; set; default = 0; }

    private Spice.Services.HistoryManager.HistoryAction<CanvasItem, Gdk.Rectangle?> undo_move_action;
    private Gdk.Rectangle rectangle_;
    public Gdk.Rectangle rectangle {
        get {
            rectangle_ = {real_x, real_y, real_width, real_height};
            return rectangle_;
        } set {
            real_x = value.x;
            real_y = value.y;
            real_width = value.width;
            real_height = value.height;
            check_position ();
        }
    }

    public bool item_visible {
        get {
            return this.visible;
        } set {
            this.visible = value;
            this.no_show_all = !value;
        }
    }

    protected double start_x = 0;
    protected double start_y = 0;
    protected int start_w = 0;
    protected int start_h = 0;

    public Json.Object? save_data { protected get; construct; }
    protected bool holding = false;
    protected int holding_id = 0;

    protected int real_width = 0;
    protected int real_height = 0;
    protected int real_x = 0;
    protected int real_y = 0;

    protected Gtk.Grid grid;
    protected Gtk.Revealer grabber_revealer;

    protected const string CSS = """.colored.selected {
                                     border: 2px dotted white;
                                  }""";

    public unowned Canvas canvas { protected get; construct; }

    public CanvasItem (Spice.Canvas _canvas, Json.Object _save_data) {
        Object (canvas: _canvas, save_data: _save_data);
    }

    construct {
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
        events |= Gdk.EventMask.POINTER_MOTION_MASK;

        real_width = 720;
        real_height = 510;

        var context = get_style_context ();
        context.add_class ("colored");

        Utils.set_style (this, CSS);

        /*
            Grabber Pos: 1 2 3
                         8   4
                         7 6 5
        */
        grid = new Gtk.Grid ();
        grabber_revealer = new Gtk.Revealer ();
        grabber_revealer.set_transition_duration (0);
        var grabber_grid = new Gtk.Grid ();

        grabber_grid.row_homogeneous = true;
        grabber_grid.column_homogeneous = true;

        var overlay = new Gtk.Overlay ();
        overlay.add (grid);

        var grabber_1 = make_grabber (1, Gtk.Align.START, Gtk.Align.START, overlay);
        var grabber_2 = make_grabber (2, Gtk.Align.CENTER, Gtk.Align.START, overlay);
        var grabber_3 = make_grabber (3, Gtk.Align.END, Gtk.Align.START, overlay);
        var grabber_4 = make_grabber (4, Gtk.Align.END, Gtk.Align.CENTER, overlay);
        var grabber_5 = make_grabber (5, Gtk.Align.END, Gtk.Align.END, overlay);
        var grabber_6 = make_grabber (6, Gtk.Align.CENTER, Gtk.Align.END, overlay);
        var grabber_7 = make_grabber (7, Gtk.Align.START, Gtk.Align.END, overlay);
        var grabber_8 = make_grabber (8, Gtk.Align.START, Gtk.Align.CENTER, overlay);

        clicked.connect (() => {
            grabber_1.make_visible = true;
            grabber_2.make_visible = true;
            grabber_3.make_visible = true;
            grabber_4.make_visible = true;
            grabber_5.make_visible = true;
            grabber_6.make_visible = true;
            grabber_7.make_visible = true;
            grabber_8.make_visible = true;
        });

        un_select.connect (() => {
            grabber_1.make_visible = false;
            grabber_2.make_visible = false;
            grabber_3.make_visible = false;
            grabber_4.make_visible = false;
            grabber_5.make_visible = false;
            grabber_6.make_visible = false;
            grabber_7.make_visible = false;
            grabber_8.make_visible = false;
        });

        add (overlay);
        this.show_all ();
    }

    private Grabber make_grabber (int _id, Gtk.Align _halign, Gtk.Align _valign, Gtk.Overlay overlay) {
        var grabber = new Grabber (_id);
        grabber.halign = _halign;
        grabber.valign = _valign;

        connect_grabber (grabber);

        overlay.add_overlay (grabber);

        return grabber;
    }

    public void load_data () {
        if (save_data != null) {
            real_width = (int) save_data.get_int_member ("w");
            real_height = (int) save_data.get_int_member ("h");
            real_x = (int) save_data.get_int_member ("x");
            real_y = (int) save_data.get_int_member ("y");

            load_item_data ();

            check_position ();
        }
    }

    protected abstract string serialise_item ();

    public string serialise () {
        return "{\"x\": %d,\"y\": %d,\"w\": %d,\"h\": %d,%s}\n".printf (real_x, real_y, real_width, real_height, serialise_item ());
    }

    protected virtual void load_item_data () {}

    public void unselect () {
        if (!holding) {
            un_select ();
        }
    }

    public new abstract void style ();

    private void connect_grabber (Grabber grabber) {
        grabber.grabbed.connect ((event, id) => {
            button_press_event (event);
            resize (id);
        });

        grabber.grabbed_motion.connect ((event) => {
            motion_notify_event (event);
        });

        grabber.grabbed_stoped.connect ((event) => {
            button_release_event (event);
        });
    }

    private void resize (int id) {
        holding = true;
        this.holding_id = id;
    }

    public void delete () {
        var action = new Spice.Services.HistoryManager.HistoryAction<CanvasItem, bool>.item_changed (this, "item-visible");
        Spice.Services.HistoryManager.get_instance ().add_undoable_action (action, true);

        this.item_visible = false;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        if (window.is_fullscreen) {
            return false;
        }

        if (holding) {
            return true;
        }

        undo_move_action = new Spice.Services.HistoryManager.HistoryAction<CanvasItem, Gdk.Rectangle?>.item_moved (this);

        start_x = event.x_root;
        start_y = event.y_root;
        start_w = real_width;
        start_h = real_height;

        holding = true;

        clicked ();

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (!holding) return false;

        Utils.set_cursor (Gdk.CursorType.ARROW);

        holding = false;
        holding_id = 0;

        if (delta_x == 0 && delta_y == 0 && (start_w == real_width) && (start_h == real_height)) {
            return false;
        }

        Spice.Services.HistoryManager.get_instance ().add_undoable_action (undo_move_action, true);

        move_item (delta_x, delta_y);
        delta_x = 0;
        delta_y = 0;

        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (holding) {
            int x = (int) (event.x_root - start_x);
            int y = (int) (event.y_root - start_y);
            switch (holding_id) {
                case 0:
                    Utils.set_cursor (Gdk.CursorType.FLEUR);
                    delta_x = x;
                    delta_y = y;
                    break;
                case 1:
                    Utils.set_cursor (Gdk.CursorType.TOP_LEFT_CORNER);
                    delta_x = fix_position (x, real_width, start_w);
                    delta_y = fix_position (y, real_height, start_h);
                    real_height = fix_size ((int)(start_h - 1/canvas.current_ratio * y));
                    real_width = fix_size ((int)(start_w - 1/canvas.current_ratio * x));
                    break;
                case 2:
                    Utils.set_cursor (Gdk.CursorType.TOP_SIDE);
                    delta_y = fix_position (y, real_height, start_h);
                    real_height = fix_size ((int)(start_h - 1/canvas.current_ratio * y));
                    break;
                case 3:
                    Utils.set_cursor (Gdk.CursorType.TOP_RIGHT_CORNER);
                    delta_y = fix_position (y, real_height, start_h);
                    real_height = fix_size ((int)(start_h - 1/canvas.current_ratio * y));
                    real_width = fix_size ((int)(start_w + 1/canvas.current_ratio * x));
                    break;
                case 4:
                    Utils.set_cursor (Gdk.CursorType.RIGHT_SIDE);
                    real_width = fix_size ((int)(start_w + 1/canvas.current_ratio * x));
                    break;
                case 5:
                    Utils.set_cursor (Gdk.CursorType.BOTTOM_RIGHT_CORNER);
                    real_width = fix_size ((int)(start_w + 1/canvas.current_ratio * x));
                    real_height = fix_size ((int)(start_h + 1/canvas.current_ratio * y));
                    break;
                case 6:
                    Utils.set_cursor (Gdk.CursorType.BOTTOM_SIDE);
                    real_height = fix_size ((int)(start_h + 1/canvas.current_ratio * y));
                    break;
                case 7:
                    Utils.set_cursor (Gdk.CursorType.BOTTOM_LEFT_CORNER);
                    real_height = fix_size ((int)(start_h + 1/canvas.current_ratio * y));
                    real_width = fix_size ((int)(start_w - 1/canvas.current_ratio * x));
                    delta_x = fix_position (x, real_width, start_w);;
                    break;
                case 8:
                    Utils.set_cursor (Gdk.CursorType.LEFT_SIDE);
                    real_width = fix_size ((int) (start_w - 1/canvas.current_ratio * x));
                    delta_x = fix_position (x, real_width, start_w);
                    break;
            }

            check_position ();
        }

        return false;
    }

    private int fix_position (int delta, int length, int initial_length) {
        var max_delta = (initial_length - MIN_SIZE) * canvas.current_ratio;
        if (delta < max_delta) {
            return delta;
        } else {
            return (int) max_delta;
        }
    }

    private int fix_size (int size) {
        return size > MIN_SIZE ? size : MIN_SIZE;
    }
}
