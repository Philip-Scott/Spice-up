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

public class Spice.PresenterWindow : Gtk.Window {
    public unowned Spice.SlideManager slide_manager { get; construct set; }
    public unowned Spice.Window window { get; construct set; }

    private Gtk.Image preview;
    private Gtk.Image next_preview;
    private Gtk.TextView notes;

    private bool changing = false;

    public PresenterWindow (SlideManager slide_manager, Window window) {
        Object (slide_manager: slide_manager, window: window);
    }

    construct {
        type_hint = Gdk.WindowTypeHint.DIALOG;
        resizable = false;
        stick ();

        preview = new Gtk.Image ();
        preview.valign = Gtk.Align.START;

        var preview_button = new Gtk.Button ();
        preview_button.get_style_context ().remove_class ("button");
        preview_button.get_style_context ().add_class ("flat");
        preview_button.add (preview);

        next_preview = new Gtk.Image ();
        next_preview.valign = Gtk.Align.START;

        notes = new Gtk.TextView ();
        notes.get_style_context ().add_class ("h3");
        notes.wrap_mode = Gtk.WrapMode.WORD_CHAR;
        notes.halign = Gtk.Align.FILL;
        notes.indent = 6;

        var notes_scrolled = new Gtk.ScrolledWindow (null, null);
        notes_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        notes_scrolled.height_request = 130;
        notes_scrolled.add (notes);

        var frame = new Gtk.Frame (null);
        frame.add (notes_scrolled);

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.row_spacing = 6;
        grid.column_spacing = 6;

        var separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);

        grid.attach (preview_button, 0, 0, 1, 2);
        grid.attach (next_preview,   2, 0, 1, 1);
        grid.attach (separator,      1, 0, 1, 3);
        grid.attach (frame         , 0, 2, 1, 1);

        add (grid);
        show_all ();

        connect_signals ();

        load_previews (slide_manager.current_slide);
        Timeout.add (300, () => {
            load_previews (slide_manager.current_slide);
            return false;
        });
    }

    private void connect_signals () {
        this.key_press_event.connect (on_key_pressed);

        slide_manager.current_slide_changed.connect (load_previews);

        notes.buffer.changed.connect (() => {
            if (!changing) {
                slide_manager.current_slide.notes = notes.buffer.text;
            }
        });
    }

    private void load_previews (Slide current_slide) {
        changing = true;
        notes.buffer.text = current_slide.notes;

        var next_slide = slide_manager.get_next_slide (current_slide);

        if (next_slide != null) {
            next_preview.set_from_pixbuf (next_slide.preview.pixbuf);
        }

        Timeout.add (30, () => {
            if (current_slide.canvas.surface != null) {
                var pixbuf = current_slide.canvas.surface.load_to_pixbuf ();
                pixbuf = pixbuf.scale_simple (SlideList.WIDTH * 2, SlideList.HEIGHT * 2, Gdk.InterpType.BILINEAR);
                preview.set_from_pixbuf (pixbuf);
                return false;
            }

            // Retry if not loaded...
            return true;
        });

        changing = false;
    }

    private bool on_key_pressed (Gtk.Widget source, Gdk.EventKey key) {
        debug ("Key on presenter view: %s %u", key.str, key.keyval);
        if (notes.has_focus) return false;
        switch (key.keyval) {
            // Next Slide
            case 32:    // Spaceeeeeeee
            case 65363: // Right Arrow
            case 65364: // Down Arrow
            case 65293: // Enter
            case 65366: // Page Down
                this.slide_manager.next_slide ();
                return true;

            // Previous Slide
            case 65361: // Left Arrow
            case 65362: // Up Arrow
            case 65365: // Page Up
                this.slide_manager.previous_slide ();
                return true;

            case 65307: // Esc
                end_presentation ();
                return true;
        }

        return false;
    }

    public void end_presentation () {
        window.end_presentation ();
    }
}
