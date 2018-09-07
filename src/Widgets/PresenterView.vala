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
    private Spice.SlideWidget next_preview;
    private Gtk.TextView notes;

    private bool changing = false;

    Clock clock;

    private int _font_size;
    private int font_size {
        default = 12;
        get {
            return _font_size;
        }
        set {
            if (value >= 12 && value <= 50) {
                _font_size = value;
                style ();
            }
        }
    }

    public PresenterWindow (SlideManager slide_manager, Window window) {
        Object (slide_manager: slide_manager, window: window);
    }

    construct {
        title = "Spice-Up - Presenter View";

        set_keep_above (true);
        stick ();

        clock = new Clock ();
        clock.start ();

        preview = new Gtk.Image ();
        preview.valign = Gtk.Align.START;

        var preview_button = new Gtk.Button ();
        preview_button.get_style_context ().remove_class ("button");
        preview_button.get_style_context ().add_class ("flat");
        preview_button.add (preview);

        next_preview = new Spice.SlideWidget ();
        next_preview.valign = Gtk.Align.START;
        next_preview.show_button = false;

        var next_preview_button = new Gtk.Button ();
        next_preview_button.get_style_context ().add_class ("padding-none");
        next_preview_button.get_style_context ().add_class ("flat");
        next_preview_button.valign = Gtk.Align.START;
        next_preview_button.halign = Gtk.Align.CENTER;

        next_preview_button.add (next_preview);

        notes = new Gtk.TextView ();
        notes.get_style_context ().add_class ("h3");
        notes.wrap_mode = Gtk.WrapMode.WORD_CHAR;
        notes.halign = Gtk.Align.FILL;
        notes.indent = 6;

        font_size = 12;

        var notes_scrolled = new Gtk.ScrolledWindow (null, null);
        notes_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        notes_scrolled.height_request = 130;
        notes_scrolled.add (notes);

        var frame = new Gtk.Frame (null);
        frame.add (notes_scrolled);
        frame.expand = true;

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.row_spacing = 6;
        grid.column_spacing = 6;

        var separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);

        var timer = new Clock ();
        timer.start ();

        var controller = new SlideshowController (slide_manager);

        grid.attach (preview_button     , 0, 0, 1, 2);
        grid.attach (next_preview_button, 2, 0, 1, 1);
        grid.attach (separator          , 1, 0, 1, 3);
        grid.attach (frame              , 0, 2, 1, 1);
        grid.attach (timer              , 2, 1, 1, 1);
        grid.attach (controller         , 2, 2, 1, 1);

        add (grid);
        show_all ();

        load_previews (slide_manager.current_slide);
        Timeout.add (300, () => {
            load_previews (slide_manager.current_slide);
            return false;
        });

        this.key_press_event.connect (on_key_pressed);

        slide_manager.current_slide_changed.connect (load_previews);

        notes.buffer.changed.connect (() => {
            if (!changing) {
                slide_manager.current_slide.notes = notes.buffer.text;
            }
        });

        next_preview_button.clicked.connect (slide_manager.next_slide);
    }

    private void load_previews (Slide current_slide) {
        changing = true;
        notes.buffer.text = current_slide.notes;

        var next_slide = slide_manager.get_next_slide (current_slide);

        if (next_slide != null) {
            next_preview.pixbuf = next_slide.preview.pixbuf;
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
            case 61: // =
            case 43: // +
                font_size = font_size + 2;
                return true;
            case 45: // -
                font_size = font_size - 2;
                return true;
        }

        return false;
    }

    public void end_presentation () {
        window.end_presentation ();
    }

    private void style () {
        var notes_css = NOTES_CSS.printf (font_size);
        Utils.set_style (notes, notes_css);
    }

    private const string NOTES_CSS = """
    .view {
        font-size: %dpx;
    }""";

    private class SlideshowController : Gtk.Grid {
        public unowned Spice.SlideManager slide_manager { get; construct set; }

        public int slide_count { get; construct set; }

        private Gtk.ProgressBar progress_bar;

        public SlideshowController (SlideManager slide_manager) {
            Object (slide_manager: slide_manager, slide_count: slide_manager.get_slide_ammount (), column_spacing: 3);
        }

        construct {
            var next_button = new Gtk.Button.from_icon_name ("go-next-symbolic", Gtk.IconSize.DND);
            var back_button = new Gtk.Button.from_icon_name ("go-previous-symbolic", Gtk.IconSize.DND);

            next_button.clicked.connect (slide_manager.next_slide);
            back_button.clicked.connect (slide_manager.previous_slide);

            next_button.get_style_context ().add_class ("circular");
            back_button.get_style_context ().add_class ("circular");

            next_button.valign = Gtk.Align.CENTER;
            back_button.valign = Gtk.Align.CENTER;

            slide_manager.current_slide_changed.connect (update);

            progress_bar = new  Gtk.ProgressBar ();
            progress_bar.ellipsize = Pango.EllipsizeMode.MIDDLE;
            progress_bar.get_style_context ().add_class ("h2");
            progress_bar.valign = Gtk.Align.CENTER;
            progress_bar.show_text = true;
            progress_bar.expand = true;

            valign = Gtk.Align.END;

            add (back_button);
            add (progress_bar);
            add (next_button);

            update (slide_manager.current_slide);
        }

        private void update (Slide slide) {
            slide_manager.get_slide_pos (slide);

            var slide_pos = slide_manager.get_slide_pos (slide);

            if (slide_pos != -1) {
                progress_bar.fraction = (double) slide_pos / (double) slide_count;
                progress_bar.text = _("%d of %d").printf (slide_pos, slide_count);
            } else {
                progress_bar.text = _("End");
            }
        }
    }

    private class Clock : Gtk.Grid {
        private struct Time {
            int hours;
            int minutes;
            int seconds;
        }

        private Timer? timer = null;
        private bool started = false;
        private Gtk.Label label;
        private Gtk.Image pause_image;

        construct {
            halign = Gtk.Align.CENTER;
            valign = Gtk.Align.CENTER;
            column_spacing = 6;

            label = new Gtk.Label ("00:00:00");
            label.get_style_context ().add_class ("h1");

            pause_image = new Gtk.Image.from_icon_name ("media-playback-pause-symbolic", Gtk.IconSize.BUTTON);
            var reset_image = new Gtk.Image.from_icon_name ("media-playback-stop-symbolic", Gtk.IconSize.BUTTON);

            var reset_button = new Gtk.Button ();
            var pause_button = new Gtk.Button ();

            reset_button.add (reset_image);
            pause_button.add (pause_image);

            reset_button.clicked.connect (reset);
            pause_button.clicked.connect (() => {
                if (started) {
                    stop ();
                } else {
                    start ();
                }
            });

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
            box.margin = 6;

            box.add (pause_button);
            box.add (reset_button);
            add (label);
            add (box);
        }

        private void update () {
            var t = parse_time ((int) timer.elapsed ());
            string time = "%s:%s:%s".printf (get_part (t.hours), get_part (t.minutes), get_part (t.seconds));
            label.label = time;
        }

        private string get_part (int number) {
            return number > 9 ? "%d".printf (number) : "0%d".printf (number);
        }

        private Time parse_time (int time) {
            var t = Time ();
            t.seconds = time % 60;

            time = time / 60;
            t.minutes = time % 60;

            time = time / 60;
            t.hours = time / 60;

            return t;
        }

        public void start () {
            if (timer == null) {
                timer = new Timer ();
                timer.start ();
            } else {
                timer.@continue ();
            }

            started = true;
            Timeout.add (1000, () => {
                update ();
                return this.started;
            });

            pause_image.icon_name = "media-playback-pause-symbolic";
        }

        public void stop () {
            started = false;
            timer.stop ();
            pause_image.icon_name = "media-playback-start-symbolic";
        }

        public void reset () {
            timer = null;
            started = false;
            label.label = "00:00:00";
            pause_image.icon_name = "media-playback-start-symbolic";
        }
    }
}
