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

            present.tooltip_text = value ? _("Stop Presentation") : _("Start Presentation");
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
        HeaderbarButton.headerbar = this;
        has_subtitle = false;

        undo = new HeaderbarButton ("edit-undo-symbolic", _("Undo"), HeaderButton.UNDO, {"<Ctrl>Z"});
        redo = new HeaderbarButton ("edit-redo-symbolic", _("Redo"), HeaderButton.REDO, {"<Ctrl><Shift>Z"});
        text = new HeaderbarButton ("text-symbolic", _("Insert Text Box"), HeaderButton.TEXT);
        image = new HeaderbarButton ("photo-symbolic", _("Insert Image"), HeaderButton.IMAGE);
        shape = new HeaderbarButton ("shape-symbolic", _("Insert Shape"), HeaderButton.SHAPE);
        show_welcome = new HeaderbarButton ("document-open-symbolic", _("Return to Welcome Screen"), HeaderButton.RETURN);

        undo.sensitive = false;
        redo.sensitive = false;

        export = new HeaderbarButton ("document-export-symbolic", _("Export to PDF"), null);
        present = new HeaderbarButton ("media-playback-start-symbolic", _("Start Presentation"), null, {"<Ctrl><Shift>P"});
        present.get_style_context ().add_class ("suggested-action");

        show_notes = new Gtk.ToggleButton ();
        show_notes.can_focus = false;

        Gtk.Image show_notes_image = new Gtk.Image.from_icon_name ("accessories-text-editor-symbolic", Gtk.IconSize.BUTTON);
        show_notes_image.margin = 3;

        show_notes.get_style_context ().add_class ("spice");
        show_notes.set_tooltip_text (_("Presenter Notes"));
        show_notes.add (show_notes_image);
        show_notes.clicked.connect (() => {
            button_clicked (Spice.HeaderButton.NOTES);
        });

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
        Spice.Services.HistoryManager.get_instance ().undo_changed.connect ((is_empty) => {
            undo.sensitive = !is_empty;
        });

        Spice.Services.HistoryManager.get_instance ().redo_changed.connect ((is_empty) => {
            redo.sensitive = !is_empty;
        });

        undo.clicked.connect (() => {
            Spice.Services.HistoryManager.get_instance ().undo ();
        });

        redo.clicked.connect (() => {
            Spice.Services.HistoryManager.get_instance ().redo ();
        });

        present.clicked.connect (() => {
            window.is_presenting = !window.is_presenting;
        });

        export.clicked.connect (() => {
            Spice.Services.FileManager.export_to_pdf (this.slide_manager);
        });
    }

    protected class HeaderbarButton : Gtk.Button {
        public static Headerbar headerbar;

        public HeaderbarButton (string icon_name, string description, HeaderButton? signal_mask, string[] accels = null) {
            can_focus = false;

            Gtk.Image image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.BUTTON);
            image.margin = 3;

            get_style_context ().add_class ("spice");
            set_tooltip_markup (Granite.markup_accel_tooltip (accels, description));
            this.add (image);

            if (signal_mask != null) {
                this.clicked.connect (() => {
                    headerbar.button_clicked (signal_mask);
                });
            }
        }
    }
}
