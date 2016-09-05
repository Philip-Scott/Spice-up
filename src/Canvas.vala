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
    private const int SNAP_LIMIT = int.MAX - 1;

    public signal void configuration_changed ();

    private bool scanning = false;
    private double current_ratio = 1.0f;
    private int current_allocated_width = 0;
    private int current_allocated_height = 0;
    private int default_x_margin = 0;
    private int default_y_margin = 0;
    public int active_displays { get; set; default = 0; }
    private static string[] colors = {"#3892e0", "#da4d45", "#f37329", "#fbd25d", "#93d844", "#8a4ebf", "#333333"};

    const string COLORED_STYLE_CSS = """
        .colored {
            background-color: %s;
            color: %s;
        }

        .colored.disabled {
            background-color: #aaa;
        }
    """;

    public Canvas () {
        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        grid.expand = true;
        add (grid);

        add_output ();
        add_output ();
        add_output ();
        add_output ();
        add_output ();
        add_output ();

        calculate_ratio ();
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
        try {
            configuration_changed ();
        } catch (Error e) {
            // Nothing to show here
        }
    }

    private void calculate_ratio () {
        int added_width = 0;
        int added_height = 0;
        int max_width = 0;
        int max_height = 0;
        get_children ().foreach ((child) => {
            if (child is CanvasItem) {
                var display_widget = (CanvasItem) child;
                int x = 20, y = 20, width = 200, height = 200;
                added_width += width;
                added_height += height;
                max_width = int.max (max_width, x + width);
                max_height = int.max (max_height, y + height);
            }
        });
        current_allocated_width = get_allocated_width ();
        current_allocated_height = get_allocated_height ();
        current_ratio = double.min ((double)(get_allocated_width () -24) / (double) added_width, (double)(get_allocated_height ()-24) / (double) added_height);
        default_x_margin = (int) ((get_allocated_width () - max_width*current_ratio)/2);
        default_y_margin = (int) ((get_allocated_height () - max_height*current_ratio)/2);
    }

    private void add_output () {
        var display_widget = new CanvasItem ();
        current_allocated_width = 0;
        current_allocated_height = 0;
        add_overlay (display_widget);
        var provider = new Gtk.CssProvider ();
        try {
            var color_number = (get_children ().length ()-2)%7;
            var font_color = "#ffffff";
            if (color_number == 3 || color_number == 4) {
                font_color = "#333333";
            }

            var colored_css = COLORED_STYLE_CSS.printf (colors[color_number], font_color);
            provider.load_from_data (colored_css, colored_css.length);
            var context = display_widget.get_style_context ();
            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            context.add_class ("colored");
//            context = display_widget.display_window.get_style_context ();
  //          context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    //        context.add_class ("colored");
        } catch (GLib.Error e) {
            critical (e.message);
        }

        display_widget.show_all ();
        display_widget.configuration_changed.connect (() => check_configuration_changed ());
        display_widget.check_position.connect (() => check_intersects (display_widget));
        display_widget.active_changed.connect (() => {
            active_displays += 1;
            check_configuration_changed ();
            calculate_ratio ();
        });

        display_widget.show_all ();

        display_widget.move_display.connect ((delta_x, delta_y) => {
            int x, y, width, height;
            display_widget.get_geometry (out x, out y, out width, out height);
            display_widget.set_geometry ((int)(delta_x / current_ratio) + x, (int)(delta_y / current_ratio) + y, width, height);
            display_widget.queue_resize_no_redraw ();
            check_configuration_changed ();
            //snap_edges (display_widget);
            calculate_ratio ();
        });

        //check_intersects (display_widget);
        var old_delta_x = display_widget.delta_x;
        var old_delta_y = display_widget.delta_y;
        display_widget.delta_x = 0;
        display_widget.delta_y = 0;
        display_widget.move_display (old_delta_x, old_delta_y);
        
        calculate_ratio ();
    }
    
    public void check_intersects (CanvasItem source_display_widget) {
        int orig_x, orig_y, src_x, src_y, src_width, src_height;
        source_display_widget.get_geometry (out orig_x, out orig_y, out src_width, out src_height);
        src_x = orig_x + (int)(source_display_widget.delta_x/current_ratio);
        src_y = orig_y + (int)(source_display_widget.delta_y/current_ratio);
        Gdk.Rectangle src_rect = {src_x, src_y, src_width, src_height};
        get_children ().foreach ((child) => {
            if (child is Spice.CanvasItem) {
                var display_widget = (Spice.CanvasItem) child;
                if (display_widget == source_display_widget) {
                    return;
                }

                int x, y, width, height;
                display_widget.get_geometry (out x, out y, out width, out height);
                Gdk.Rectangle test_rect = {x, y, width, height};
                /*Gdk.Rectangle intersection;
                if (src_rect.intersect (test_rect, out intersection)) {
                    if (intersection.height == src_height) {
                        // on the left side
                        if (intersection.x <= x + width/2) {
                            source_display_widget.delta_x = (int) ((x - (orig_x + src_width)) * current_ratio);
                        // on the right side
                        } else {
                            source_display_widget.delta_x = (int) ((x - orig_x + width) * current_ratio);
                        }
                    } else if (intersection.width == src_width) {
                        // on the bottom side
                        if (intersection.y <= y + height/2) {
                            source_display_widget.delta_y = (int) ((y - (orig_y + src_height)) * current_ratio);
                        } else {
                        // on the upper side
                            source_display_widget.delta_y = (int) ((y - orig_y + height) * current_ratio);
                        }
                    } else {
                        if (intersection.width < intersection.height) {
                            // on the left side
                            if (intersection.x <= x + width/2) {
                                source_display_widget.delta_x = (int) ((x - (orig_x + src_width)) * current_ratio);
                            // on the right side
                            } else {
                                source_display_widget.delta_x = (int) ((x - orig_x + width) * current_ratio);
                            }
                        } else {
                            // on the bottom side
                            if (intersection.y <= y + height/2) {
                                source_display_widget.delta_y = (int) ((y - (orig_y + src_height)) * current_ratio);
                            } else {
                            // on the upper side
                                source_display_widget.delta_y = (int) ((y - orig_y + height) * current_ratio);
                            }
                        }
                    }
                }*/
            }
        });

        source_display_widget.queue_resize_no_redraw ();
    }
}
