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

public class Spice.Grabber : Gtk.Button {
    public signal void grabbed (Gdk.EventButton event, int id);
    public signal void grabbed_motion (Gdk.EventMotion event);
    public signal void grabbed_stoped (Gdk.EventButton event);

    private int id;

    public bool make_visible {
        set {
            visible = value;
            no_show_all = !value;
            show_all ();
        }
    }

    public Grabber (int id) {
        this.id = id;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
        events |= Gdk.EventMask.POINTER_MOTION_MASK;

        get_style_context ().remove_class ("button");

        var image = new Gtk.Image.from_resource ("/com/github/philip-scott/spice-up/drag.svg");
        this.add (image);

        make_visible = false;
    }

    public override bool draw (Cairo.Context ctx) {
        if (window.is_fullscreen || Canvas.drawing_preview) return false;

        return base.draw (ctx);
    }


    public override bool button_press_event (Gdk.EventButton event) {
        grabbed (event, id);
        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        grabbed_stoped (event);
        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        grabbed_motion (event);
        return true;
    }
}

