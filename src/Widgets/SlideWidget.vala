/*
* Copyright (c) 2017 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

public class Spice.SlideWidget : Gtk.EventBox {
    public signal void settings_requested ();

    public Gdk.Pixbuf pixbuf {
        set {
            this.image.set_from_pixbuf (value);
        }
    }

    public bool show_button = true;

    private Gtk.Overlay overlay;
    private Gtk.Image image;
    public Gtk.Revealer settings_revealer;

    public Spice.SlideWidget.from_slide (Slide slide) {
        this.overlay.add (slide.preview);
        slide.preview.get_style_context ().add_class ("card");
    }

    public SlideWidget () {
        image = new Gtk.Image ();
        image.get_style_context ().add_class ("card");
        overlay.add (image);
    }

    construct {
        events |= Gdk.EventMask.ENTER_NOTIFY_MASK & Gdk.EventMask.LEAVE_NOTIFY_MASK;

        overlay = new Gtk.Overlay ();
        overlay.margin = 9;

        var settings_button = new Gtk.Button.from_icon_name ("document-properties-symbolic", Gtk.IconSize.BUTTON);
        settings_button.events |= Gdk.EventMask.ENTER_NOTIFY_MASK & Gdk.EventMask.LEAVE_NOTIFY_MASK;
        settings_button.get_style_context ().add_class ("flat");
        settings_button.get_style_context ().add_class ("icon-shadow");
        settings_button.can_focus = false;

        settings_revealer = new Gtk.Revealer ();
        settings_revealer.set_transition_duration (500);
        settings_revealer.set_transition_type (Gtk.RevealerTransitionType.CROSSFADE);
        settings_revealer.halign = Gtk.Align.START;
        settings_revealer.valign = Gtk.Align.START;
        settings_revealer.add (settings_button);

        add (overlay);
        overlay.add_overlay (settings_revealer);

        settings_button.clicked.connect (() => {settings_requested ();});

        settings_button.enter_notify_event.connect ((event) => {
            settings_revealer.set_reveal_child (this.show_button);
            return false;
        });

        enter_notify_event.connect ((event) => {
            settings_revealer.set_reveal_child (this.show_button);
            return false;
        });

        leave_notify_event.connect ((event) => {
            settings_revealer.set_reveal_child (false);
            return false;
        });
    }
}