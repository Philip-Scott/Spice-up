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
    TEXT,
    IMAGE,
    SHAPE,
    RETURN,
    NOTES;
}

public class Spice.Headerbar : Gtk.HeaderBar {
    public signal void button_clicked (Spice.HeaderButton button);

    private HeaderbarButton undo;
    private HeaderbarButton redo;
    private HeaderbarButton text;
    private HeaderbarButton image;
    private HeaderbarButton shape;
    private HeaderbarButton export;
    private HeaderbarButton show_welcome;
    private HeaderbarButton present;

    private Gtk.ToggleButton show_notes;

    private Spice.SlideManager slide_manager;

    public new bool sensitive {
        get {
            return present.sensitive;
        }
        set {
            text.sensitive = value;
            undo.sensitive = false;
            redo.sensitive = false;
            shape.sensitive = value;
            image.sensitive = value;
            export.sensitive = value;
            present.sensitive = value;
            show_welcome.sensitive = value;
            show_notes.sensitive = value;
        }
    }

    public bool is_presenting {
        set {
            text.visible = !value;
            undo.visible = !value;
            redo.visible = !value;
            shape.visible = !value;
            image.visible = !value;
            export.visible = !value;
            show_welcome.visible = !value;
            show_notes.visible = !value;

            text.no_show_all = value;
            undo.no_show_all = value;
            redo.no_show_all = value;
            shape.no_show_all = value;
            image.no_show_all = value;
            export.no_show_all = value;
            show_welcome.no_show_all = value;
            show_notes.no_show_all = value;

            present.tooltip_markup = value ?
                Utils.get_accel_tooltip (Window.ACTION_PRESENT_STOP, _("Stop Presentation")) :
                Utils.get_accel_tooltip (Window.ACTION_PRESENT_START, _("Start Presentation"));
        }
    }

    private bool notes_state_set = false;
    public bool notes_shown {
        set {
            if (value != show_notes.active) {
                notes_state_set = true;
                show_notes.active = value;
                notes_state_set = false;
            }
        }
    }

    public Headerbar (Spice.SlideManager slide_manager) {
        this.slide_manager = slide_manager;
        set_title ("Presentation");
        set_show_close_button (true);

        build_ui ();
        connect_signals ();
    }

    private void build_ui () {
        has_subtitle = false;

        undo = new HeaderbarButton (this, "edit-undo-symbolic", Utils.get_accel_tooltip (Window.ACTION_UNDO, _("Undo")));
        redo = new HeaderbarButton (this, "edit-redo-symbolic", Utils.get_accel_tooltip (Window.ACTION_REDO, _("Redo")));
        text = new HeaderbarButton (this, "text-symbolic", Utils.get_accel_tooltip ("", _("Insert Text Box")), HeaderButton.TEXT);
        image = new HeaderbarButton (this, "photo-symbolic", Utils.get_accel_tooltip ("", _("Insert Image")), HeaderButton.IMAGE);
        shape = new HeaderbarButton (this, "shape-symbolic", Utils.get_accel_tooltip ("", _("Insert Shape")), HeaderButton.SHAPE);
        show_welcome = new HeaderbarButton (this, "document-open-symbolic", Utils.get_accel_tooltip (Window.ACTION_SHOW_WELCOME, _("Return to Welcome Screen")));

        undo.sensitive = false;
        redo.sensitive = false;

        export = new HeaderbarButton (this, "document-export-symbolic", Utils.get_accel_tooltip (Window.ACTION_EXPORT, _("Export to PDF")));
        present = new HeaderbarButton (this, "media-playback-start-symbolic", Utils.get_accel_tooltip (Window.ACTION_PRESENT_START, _("Start Presentation")));
        present.get_style_context ().add_class ("suggested-action");

        show_notes = new Gtk.ToggleButton ();
        show_notes.can_focus = false;

        Gtk.Image show_notes_image = new Gtk.Image.from_icon_name ("accessories-text-editor-symbolic", Gtk.IconSize.BUTTON);
        show_notes_image.margin = 3;

        show_notes.get_style_context ().add_class ("spice");
        show_notes.tooltip_markup = Utils.get_accel_tooltip (Window.ACTION_NOTES, _("Presenter Notes"));
        show_notes.add (show_notes_image);

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
        pack_end (export);
        pack_end (show_welcome);
        pack_end (show_notes);
    }

    private void connect_signals () {
        slide_manager.window.history_manager.undo_changed.connect ((is_empty) => {
            undo.sensitive = !is_empty;
        });

        slide_manager.window.history_manager.redo_changed.connect ((is_empty) => {
            redo.sensitive = !is_empty;
        });

        undo.clicked.connect (() => {
            slide_manager.window.action_undo ();
        });

        redo.clicked.connect (() => {
            slide_manager.window.action_redo ();
        });

        present.clicked.connect (() => {
            slide_manager.window.action_present_toggle ();
        });

        show_notes.toggled.connect (() => {
            if (!notes_state_set) {
                slide_manager.window.action_toggle_notes ();
            }
        });

        show_welcome.clicked.connect (slide_manager.window.show_welcome);
        export.clicked.connect (slide_manager.window.action_export);
    }

    protected class HeaderbarButton : Gtk.Button {

        public HeaderbarButton (Headerbar headerbar, string icon_name, string description, HeaderButton? signal_mask = null) {
            can_focus = false;

            Gtk.Image image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.BUTTON);
            image.margin = 3;

            get_style_context ().add_class ("spice");
            set_tooltip_markup (description);
            this.add (image);

            if (signal_mask != null) {
                this.clicked.connect (() => {
                    headerbar.button_clicked (signal_mask);
                });
            }
        }
    }
}
