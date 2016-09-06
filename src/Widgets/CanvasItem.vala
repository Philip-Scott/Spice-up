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

public class Spice.CanvasItem : Gtk.EventBox {
    public signal void set_as_primary ();
    public signal void move_display (int delta_x, int delta_y);
    public signal void check_position ();
    public signal void configuration_changed ();
    public signal void active_changed ();

    public int delta_x { get; set; default = 0; }
    public int delta_y { get; set; default = 0; }
    public bool only_display { get; set; default = false; }
    private double start_x = 0;
    private double start_y = 0;
    private bool holding = false;
    private Gtk.Button primary_image;

    private int real_width = 0;
    private int real_height = 0;
    private int real_x = 0;
    private int real_y = 0;

    struct Resolution {
        uint width;
        uint height;
    }

    public CanvasItem () {
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
        events |= Gdk.EventMask.POINTER_MOTION_MASK;

        real_width = 720;
        real_height = 510;

        primary_image = new Gtk.Button.from_icon_name ("non-starred-symbolic", Gtk.IconSize.MENU);
        primary_image.margin = 6;
        primary_image.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        primary_image.halign = Gtk.Align.START;
        primary_image.valign = Gtk.Align.START;

        var toggle_settings = new Gtk.ToggleButton ();
        toggle_settings.margin = 6;
        toggle_settings.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        toggle_settings.halign = Gtk.Align.END;
        toggle_settings.valign = Gtk.Align.START;
        toggle_settings.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.MENU);
        toggle_settings.tooltip_text = _("Configure display");

        var label = new Gtk.Label ("Some Text Can Be Here");
        label.halign = Gtk.Align.CENTER;
        label.valign = Gtk.Align.CENTER;
        label.expand = true;

        var grid = new Gtk.Grid ();
        //grid.attach (primary_image, 0, 0, 1, 1);
        //grid.attach (toggle_settings, 2, 0, 1, 1);
        grid.attach (label, 0, 0, 3, 2);
        add (grid);

        var popover_grid = new Gtk.Grid ();
        popover_grid.column_spacing = 12;
        popover_grid.row_spacing = 6;
        popover_grid.margin = 12;
        var popover = new Gtk.Popover (toggle_settings);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.bind_property ("visible", toggle_settings, "active", GLib.BindingFlags.BIDIRECTIONAL);
        popover.add (popover_grid);

        var use_label = new Gtk.Label (_("Use This Display:"));
        use_label.halign = Gtk.Align.END;
        var use_switch = new Gtk.Switch ();
        use_switch.halign = Gtk.Align.START;
        this.bind_property ("only-display", use_switch, "sensitive", GLib.BindingFlags.INVERT_BOOLEAN);

        var resolution_label = new Gtk.Label (_("Resolution:"));
        resolution_label.halign = Gtk.Align.END;

        popover_grid.attach (use_label, 0, 0, 1, 1);
        popover_grid.attach (use_switch, 1, 0, 1, 1);
        popover_grid.attach (resolution_label, 0, 1, 1, 1);

        popover_grid.show_all ();

        configuration_changed ();
        check_position ();
    }

    public override bool button_press_event (Gdk.EventButton event) {
        if (only_display) {
            return false;
        }

        start_x = event.x_root;
        start_y = event.y_root;
        
        holding = true;
        return false;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if ((delta_x == 0 && delta_y == 0)) {
            return false;
        }

        var old_delta_x = delta_x;
        var old_delta_y = delta_y;
        delta_x = 0;
        delta_y = 0;
        move_display (old_delta_x, old_delta_y);
        holding = false;
        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (holding) {
            delta_x = (int)(event.x_root - start_x);
            delta_y = (int)(event.y_root - start_y);
            check_position ();
        }

        return false;
    }

    public void get_geometry (out int x, out int y, out int width, out int height) {
        x = real_x;
        y = real_y;
        width = real_width;
        height = real_height;
    }

    public void set_geometry (int x, int y, int width, int height) {
        real_x = x;
        real_y = y;
        real_width = width;
        real_height = height;
    }

    // copied from GCC panel
    public static string? make_aspect_string (uint width, uint height) {
        uint ratio;
        string? aspect = null;

        if (width == 0 || height == 0)
            return null;

        if (width > height) {
            ratio = width * 10 / height;
        } else {
            ratio = height * 10 / width;
        }

        switch (ratio) {
            case 13:
                aspect = "4∶3";
                break;
            case 16:
                aspect = "16∶10";
                break;
            case 17:
                aspect = "16∶9";
                break;
            case 23:
                aspect = "21∶9";
                break;
            case 12:
                aspect = "5∶4";
                break;
                /* This catches 1.5625 as well (1600x1024) when maybe it shouldn't. */
            case 15:
                aspect = "3∶2";
                break;
            case 18:
                aspect = "9∶5";
                break;
            case 10:
                aspect = "1∶1";
                break;
        }

        return aspect;
    }
}
