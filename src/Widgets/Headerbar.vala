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

public enum Spice.HeaderButton {
    UNDO,
    REDO,
    TEXT,
    IMAGE,
    SHAPE;
}

public class Spice.Headerbar : Gtk.HeaderBar {
    public signal void button_clicked (Spice.HeaderButton button);

    private HeaderbarButton undo;
    private HeaderbarButton redo;
    private HeaderbarButton text;
    private HeaderbarButton image;
    private HeaderbarButton shape;

    private HeaderbarButton present;

    public new bool sensitive {
        get {
            return present.sensitive;
        }
        set {
            undo.sensitive = value;
            redo.sensitive = value;
            text.sensitive = value;
            image.sensitive = value;
            shape.sensitive = value;
            present.sensitive = value;
        }
    }

    public Headerbar () {
        set_title ("Presentation");
        set_show_close_button (true);

        build_ui ();
        connect_signals ();
    }

    private void build_ui () {
        HeaderbarButton.headerbar = this;

        undo = new HeaderbarButton ("edit-undo-symbolic", HeaderButton.UNDO);
        redo = new HeaderbarButton ("edit-redo-symbolic", HeaderButton.REDO);
        text = new HeaderbarButton ("insert-text-symbolic", HeaderButton.TEXT);
        image = new HeaderbarButton ("insert-image-symbolic", HeaderButton.IMAGE);
        shape = new HeaderbarButton ("insert-object-symbolic", HeaderButton.SHAPE);

        present = new HeaderbarButton ("media-playback-start-symbolic", null);
        present.get_style_context ().add_class ("suggested-action");

        var undo_redo_box = new Gtk.Grid ();
        var object_box = new Gtk.Grid ();

        undo_redo_box.get_style_context ().add_class ("linked");
        object_box.get_style_context ().add_class ("linked");

        undo_redo_box.add (undo);
        undo_redo_box.add (redo);

        object_box.add (text);
        object_box.add (image);
        object_box.add (shape);

        pack_start (undo_redo_box);
        pack_start (object_box);

        pack_end (present);
    }

    private void connect_signals () {
        present.clicked.connect (() => {
            window.fullscreen ();
        });
    }

    protected class HeaderbarButton : Gtk.Button {
        public static Headerbar headerbar;

        protected HeaderbarButton (string icon_name, HeaderButton? signal_mask) {
            can_focus = false;

            var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.BUTTON);
            image.margin = 3;

            get_style_context ().add_class ("spice");

            this.add (image);

            if (signal_mask != null) {
                this.clicked.connect (() => {
                    headerbar.button_clicked (signal_mask);
                });
            }
        }
    }
}


