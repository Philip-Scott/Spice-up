
/*
* Copyright (c) 2017 Ronny Dobra (https://github.com/RonnyDo/ColorPicker)
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
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Ronny Dobra <ronnydobra at arcor dot de>
* Inspired by: https://github.com/stuartlangridge/ColourPicker/
*/

public class Spice.PickerWindow : Granite.Widgets.CompositedWindow {
    public signal void picked (Gdk.RGBA color);
    public signal void cancelled ();
    public signal void moved (Gdk.RGBA color);

    const string dark_border_color_string = "#333333";
    private Gdk.RGBA dark_border_color = Gdk.RGBA ();

    const string bright_border_color_string = "#FFFFFF";
    private Gdk.RGBA bright_border_color = Gdk.RGBA ();

    private Gdk.Cursor magnifier = null;

    // 1. Snapsize is the amount of pixel going to be magnified by the zoomlevel.
    // 2. The snapsize must be odd to have a 1px magnifier center.
    // 3. Asure that snapsize * max_zoomlevel + shadow_width * 2 is smaller than 2 * get_screen ().get_display ().get_maximal_cursor_size()
    //    Valid: snapsize = 31, max_zoomlevel = 7, shadow_width = 15 --> 247px
    //           get_maximal_cursor_size = 128 --> 256px
    //    Otherwise the cursor starts to flicker. See https://github.com/stuartlangridge/ColourPicker/issues/6#issuecomment-277972290
    //    and https://github.com/RonnyDo/ColorPicker/issues/19
    const int SNAPSIZE = 31;
    const int SHADOW_WIDTH = 15;
    const int MAX_ZOOM_LEVEL = 7;
    const int MIN_ZOOM_LEVEL = 2;

    // Static so it's remembered across uses of the picker
    private static int _zoom_level = 2;
    public int zoomlevel {
        get {
            return _zoom_level;
        }
        set {
            if (value >= MIN_ZOOM_LEVEL && value <= MAX_ZOOM_LEVEL) {
                _zoom_level = value;
                set_magnifier_cursor ();
            }
        }
    }

    construct {
        type = Gtk.WindowType.POPUP;
    }

    public PickerWindow () {
        stick ();
        set_resizable (true);
        set_deletable (false);
        set_skip_taskbar_hint (true);
        set_skip_pager_hint (true);
        set_keep_above (true);

        dark_border_color.parse (dark_border_color_string);
        bright_border_color.parse (bright_border_color_string);

        var display = Gdk.Display.get_default ();

        Gdk.Rectangle? screens_rectangle = null;
        var n_monitors = display.get_n_monitors ();

        for (int i = 0; i < n_monitors; i++) {
            var monitor = display.get_monitor (i);

            if (screens_rectangle == null) {
                screens_rectangle = monitor.get_geometry ();
            } else {
                var rectangle = monitor.get_geometry ();
                screens_rectangle.union (rectangle, out screens_rectangle);
            }
        }

        set_default_size (screens_rectangle.width, screens_rectangle.height);
    }

    public override bool button_release_event (Gdk.EventButton e) {
        if (e.button == 1) {
            Gdk.RGBA color = get_color_at ((int) e.x_root, (int) e.y_root);
            picked (color);
        } else if (e.button == 3) {
            cancelled ();
        }

        return true;
    }

    public override bool draw (Cairo.Context cr) {
        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion e) {
        Gdk.RGBA color = get_color_at ((int) e.x_root, (int) e.y_root);
        moved (color);

        set_magnifier_cursor ();

        return true;
    }

    public override bool scroll_event (Gdk.EventScroll e)  {
        switch (e.direction) {
            case Gdk.ScrollDirection.UP:
                zoomlevel++;
                break;
            case Gdk.ScrollDirection.DOWN:
                zoomlevel--;
                break;
            default:
                break;
        }

        return true;
    }

    private void set_magnifier_cursor () {
        // draw cursor
        var manager = Gdk.Display.get_default ().get_default_seat ();

        int px, py;
        manager.get_pointer ().get_position (null, out px, out py);

        var radius = SNAPSIZE * zoomlevel / 2;

        // take screenshot
        var latest_pb = snap (px - SNAPSIZE / 2, py - SNAPSIZE / 2, SNAPSIZE, SNAPSIZE);

        // Zoom that screenshot up, and grab a snapsize-sized piece from the middle
        var scaled_pb = latest_pb.scale_simple (SNAPSIZE * zoomlevel + SHADOW_WIDTH * 2 , SNAPSIZE * zoomlevel + SHADOW_WIDTH * 2 , Gdk.InterpType.NEAREST);

        // Create the base surface for our cursor
        var base_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, SNAPSIZE * zoomlevel + SHADOW_WIDTH * 2 , SNAPSIZE * zoomlevel + SHADOW_WIDTH * 2);
        var base_context = new Cairo.Context (base_surface);

        // Create the circular path on our base surface
        base_context.arc (radius + SHADOW_WIDTH, radius + SHADOW_WIDTH, radius, 0, 2 * Math.PI);

        // Paste in the screenshot
        Gdk.cairo_set_source_pixbuf (base_context, scaled_pb, 0, 0);

        // Clip to that circular path, keeping the path around for later, and paint the pasted screenshot
        base_context.save ();
        base_context.clip_preserve ();
        base_context.paint ();
        base_context.restore ();

        // Draw a shadow as outside magnifier border
        double shadow_alpha = 0.6;
        base_context.set_line_width (1);

        for (int i = 0; i <= SHADOW_WIDTH; i++) {
            base_context.arc (radius + SHADOW_WIDTH, radius + SHADOW_WIDTH, radius + SHADOW_WIDTH- i, 0, 2 * Math.PI);
            Gdk.RGBA shadow_color = Gdk.RGBA();
            shadow_color.parse(dark_border_color_string);
            shadow_color.alpha = shadow_alpha / ((SHADOW_WIDTH - i + 1)*(SHADOW_WIDTH - i + 1));
            Gdk.cairo_set_source_rgba (base_context, shadow_color);
            base_context.stroke ();
        }

        // Draw an outside bright magnifier border
        Gdk.cairo_set_source_rgba (base_context, bright_border_color);
        base_context.arc (radius + SHADOW_WIDTH, radius + SHADOW_WIDTH, radius - 1, 0, 2 * Math.PI);
        base_context.stroke();

        // Draw inside square
        base_context.set_line_width (1);

        Gdk.cairo_set_source_rgba (base_context, dark_border_color);
        base_context.move_to (radius + SHADOW_WIDTH - zoomlevel, radius + SHADOW_WIDTH - zoomlevel);
        base_context.line_to (radius + SHADOW_WIDTH + zoomlevel, radius + SHADOW_WIDTH - zoomlevel);
        base_context.line_to (radius + SHADOW_WIDTH + zoomlevel, radius + SHADOW_WIDTH + zoomlevel);
        base_context.line_to (radius + SHADOW_WIDTH - zoomlevel, radius + SHADOW_WIDTH + zoomlevel);
        base_context.close_path ();
        base_context.stroke ();

        Gdk.cairo_set_source_rgba (base_context, bright_border_color);
        base_context.move_to (radius + SHADOW_WIDTH - zoomlevel + 1, radius + SHADOW_WIDTH - zoomlevel + 1);
        base_context.line_to (radius + SHADOW_WIDTH + zoomlevel - 1, radius + SHADOW_WIDTH - zoomlevel + 1);
        base_context.line_to (radius + SHADOW_WIDTH + zoomlevel - 1, radius + SHADOW_WIDTH + zoomlevel - 1);
        base_context.line_to (radius + SHADOW_WIDTH - zoomlevel + 1, radius + SHADOW_WIDTH + zoomlevel - 1);
        base_context.close_path ();
        base_context.stroke ();

        // turn the base surface into a pixbuf and thence a cursor
        var drawn_pb = Gdk.pixbuf_get_from_surface(base_surface, 0, 0, base_surface.get_width(), base_surface.get_height());

        magnifier = new Gdk.Cursor.from_pixbuf(
            get_screen ().get_display (),
            drawn_pb,
            drawn_pb.get_width () / 2,
            drawn_pb.get_height () / 2
        );

        var events = new Gdk.Event (Gdk.EventType.BUTTON_PRESS | Gdk.EventType.MOTION_NOTIFY | Gdk.EventType.SCROLL);

        // Set the cursor
        manager.grab (
            get_window (), // Window to own grab
            Gdk.SeatCapabilities.ALL,
            true, // Owner events
            magnifier, // Cursor
            events,
            null
        );
    }

    public Gdk.Pixbuf? snap (int x, int y, int w, int h) {
        var root = Gdk.get_default_root_window ();

        var screenshot = Gdk.pixbuf_get_from_window (root, x, y, w, h);
        return screenshot;
    }

    public override bool key_press_event (Gdk.EventKey e) {
        if (e.keyval == Gdk.Key.Escape) {
            cancelled ();
        }

        return true;
    }

    public Gdk.RGBA get_color_at (int x, int y) {
        var root = Gdk.get_default_root_window ();
        Gdk.Pixbuf? pixbuf = Gdk.pixbuf_get_from_window (root, x, y, 1, 1);

        if (pixbuf != null) {
            // see https://hackage.haskell.org/package/gtk3-0.14.6/docs/Graphics-UI-Gtk-Gdk-Pixbuf.html
            uint8 red = pixbuf.get_pixels()[0];
            uint8 green = pixbuf.get_pixels()[1];
            uint8 blue = pixbuf.get_pixels()[2];

            Gdk.RGBA color = Gdk.RGBA();
            string spec = "rgb(" + red.to_string() + "," + green.to_string() + "," + blue.to_string() + ")";
            if (color.parse (spec)) {
                return color;
            } else {
                warning ("Parse of pixel rgb values failed.");
            }
        }

        // fallback: default RGBA color
        warning ("Gdk.pixbuf_get_from_window failed");
        return Gdk.RGBA ();
    }

    public override void show_all () {
        base.show_all ();

        var manager = Gdk.Display.get_default ().get_default_seat ();
        var window = get_window ();

        var events = new Gdk.Event (Gdk.EventType.BUTTON_PRESS | Gdk.EventType.MOTION_NOTIFY | Gdk.EventType.SCROLL);

        // Set the cursor
        var status = manager.grab (
            window,
            Gdk.SeatCapabilities.ALL,
            true, // Owner events
            new Gdk.Cursor.for_display (window.get_display (), Gdk.CursorType.CROSSHAIR),
            events,
            null
        );

        if (status != Gdk.GrabStatus.SUCCESS) {
            manager.ungrab ();
        }

        // show magnifier
        set_magnifier_cursor ();
    }

    public new void close () {
        get_window ().set_cursor (null);
        base.close ();
    }

}

public struct ExtRGBA : Gdk.RGBA {
    public string to_css_rgb_string () {
        string s = "rgb(%i, %i, %i)"
            .printf((int) (this.red * 255),
                    (int) (this.green * 255),
                    (int) (this.blue * 255));
        return s;
    }
}
