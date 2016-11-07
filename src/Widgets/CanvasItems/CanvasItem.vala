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

public abstract class  Spice.CanvasItem : Gtk.EventBox {
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

    protected double start_x = 0;
    protected double start_y = 0;
    protected int start_w = 0;
    protected int start_h = 0;

    protected Json.Object? save_data = null;
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

    protected Canvas canvas;

    public CanvasItem (Spice.Canvas canvas) {
        this.canvas = canvas;
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

        var grabber_1 = new Grabber (1);
        var grabber_2 = new Grabber (2);
        var grabber_3 = new Grabber (3);
        var grabber_4 = new Grabber (4);
        var grabber_5 = new Grabber (5);
        var grabber_6 = new Grabber (6);
        var grabber_7 = new Grabber (7);
        var grabber_8 = new Grabber (8);

        grabber_1.halign = Gtk.Align.START;
        grabber_1.valign = Gtk.Align.START;
        grabber_2.halign = Gtk.Align.CENTER;
        grabber_2.valign = Gtk.Align.START;
        grabber_3.halign = Gtk.Align.END;
        grabber_3.valign = Gtk.Align.START;
        grabber_4.halign = Gtk.Align.END;
        grabber_4.valign = Gtk.Align.CENTER;
        grabber_5.halign = Gtk.Align.END;
        grabber_5.valign = Gtk.Align.END;
        grabber_6.halign = Gtk.Align.CENTER;
        grabber_6.valign = Gtk.Align.END;
        grabber_7.halign = Gtk.Align.START;
        grabber_7.valign = Gtk.Align.END;
        grabber_8.halign = Gtk.Align.START;
        grabber_8.valign = Gtk.Align.CENTER;

        connect_grabber (grabber_1);
        connect_grabber (grabber_2);
        connect_grabber (grabber_3);
        connect_grabber (grabber_4);
        connect_grabber (grabber_5);
        connect_grabber (grabber_6);
        connect_grabber (grabber_7);
        connect_grabber (grabber_8);

        var overlay = new Gtk.Overlay ();
        overlay.add (grid);
        overlay.add_overlay (grabber_1);
        overlay.add_overlay (grabber_2);
        overlay.add_overlay (grabber_3);
        overlay.add_overlay (grabber_4);
        overlay.add_overlay (grabber_5);
        overlay.add_overlay (grabber_6);
        overlay.add_overlay (grabber_7);
        overlay.add_overlay (grabber_8);

        this.clicked.connect (() => {
            grabber_1.make_visible = true;
            grabber_2.make_visible = true;
            grabber_3.make_visible = true;
            grabber_4.make_visible = true;
            grabber_5.make_visible = true;
            grabber_6.make_visible = true;
            grabber_7.make_visible = true;
            grabber_8.make_visible = true;
        });

        this.un_select.connect (() => {
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

    public void load_data () {
        if (save_data != null) {
            real_width = (int) save_data.get_int_member ("w");
            real_height = (int) save_data.get_int_member ("h");
            real_x = (int) save_data.get_int_member ("x");
            real_y = (int) save_data.get_int_member ("y");

            load_item_data ();

            check_position ();
        } else {
            stderr.printf ("creating new item \n");
        }
    }

    protected abstract string serialise_item ();

    public string serialise () {
        return """ {"x": %d,"y": %d,"w": %d,"h": %d,%s}""".printf (real_x, real_y, real_width, real_height, serialise_item ());
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

    public override bool button_press_event (Gdk.EventButton event) {
        if (holding || window.is_fullscreen || !canvas.editable) {
            return false;
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
        Utils.set_cursor (Gdk.CursorType.ARROW);

        holding = false;
        holding_id = 0;

        if (delta_x == 0 && delta_y == 0 && (start_w == real_width) && (start_h == real_height)) {
            return false;
        }

        Spice.Services.HistoryManager.get_instance ().add_undoable_action (undo_move_action, true);

        var old_delta_x = delta_x;
        var old_delta_y = delta_y;
        delta_x = 0;
        delta_y = 0;
        move_item (old_delta_x, old_delta_y);

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
                    delta_x = x;
                    delta_y = y;
                    real_height = (int)(start_h - 1/canvas.current_ratio * y);
                    real_width = (int)(start_w - 1/canvas.current_ratio * x);
                    break;
                case 2:
                    Utils.set_cursor (Gdk.CursorType.TOP_SIDE);
                    delta_y = y;
                    real_height = (int)(start_h - 1/canvas.current_ratio * y);
                    break;
                case 3:
                    Utils.set_cursor (Gdk.CursorType.TOP_RIGHT_CORNER);
                    delta_y = y;
                    real_height = (int)(start_h - 1/canvas.current_ratio * y);
                    real_width = (int)(start_w + 1/canvas.current_ratio * x);
                    break;
                case 4:
                    Utils.set_cursor (Gdk.CursorType.RIGHT_SIDE);
                    real_width = (int)(start_w + 1/canvas.current_ratio * x);
                    break;
                case 5:
                    Utils.set_cursor (Gdk.CursorType.BOTTOM_RIGHT_CORNER);
                    real_width = (int)(start_w + 1/canvas.current_ratio * x);
                    real_height = (int)(start_h + 1/canvas.current_ratio * y);
                    break;
                case 6:
                    Utils.set_cursor (Gdk.CursorType.BOTTOM_SIDE);
                    real_height = (int)(start_h + 1/canvas.current_ratio * y);
                    break;
                case 7:
                    Utils.set_cursor (Gdk.CursorType.BOTTOM_LEFT_CORNER);
                    real_height = (int)(start_h + 1/canvas.current_ratio * y);
                    real_width = (int)(start_w - 1/canvas.current_ratio * x);
                    delta_x = x;
                    break;
                case 8:
                    Utils.set_cursor (Gdk.CursorType.LEFT_SIDE);
                    real_width = (int)(start_w - 1/canvas.current_ratio * x);
                    delta_x = x;
                    break;
            }

            check_position ();
        }

        return false;
    }
}
