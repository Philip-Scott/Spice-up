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

    public PresenterWindow (SlideManager slide_manager, Window window) {
        Object (slide_manager: slide_manager, window: window);
    }

    construct {
        resizable = false;
        stick ();

        preview = new Gtk.Image ();
        preview.valign = Gtk.Align.START;

        next_preview = new Gtk.Image ();
        next_preview.valign = Gtk.Align.START;

        notes = new Gtk.TextView ();
        notes.wrap_mode = Gtk.WrapMode.WORD;
        notes.halign = Gtk.Align.FILL;
        notes.cursor_visible = false;
        notes.editable = false;

        notes.buffer.text = "Lorem ipsum dolor sit amet, no iisque efficiendi sed, imperdiet quaerendum qui ne. Epicuri percipitur ad sit, et nec eleifend necessitatibus. Pri eius fugit sanctus eu, luptatum legendos efficiendi quo at. Eos at quis iusto, per ut graeco iriure scaevola. Sumo doctus omittam eu sit, aperiam ullamcorper pri ad, at rebum dolores officiis per.";

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.row_spacing = 6;
        grid.column_spacing = 6;

        var separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);

        grid.attach (preview,      0, 0, 1, 2);
        grid.attach (next_preview, 2, 0, 1, 1);
        grid.attach (separator,    1, 0, 1, 3);
        grid.attach (notes,        0, 2, 1, 1);

        add (grid);
        show_all ();

        connect_signals ();

        Timeout.add (300, () => {
            load_previews (slide_manager.current_slide);
            stderr.printf ("Starting \n");
            return false;
        });
    }

    private void connect_signals () {
        this.key_press_event.connect (on_key_pressed);

        slide_manager.current_slide_changed.connect (load_previews);
    }

    private void load_previews (Slide current_slide) {
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
    }

    private bool on_key_pressed (Gtk.Widget source, Gdk.EventKey key) {
        debug ("Key on presenter view: %s %u", key.str, key.keyval);

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
