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

public class Spice.SlideManager : Object {
    public static int aspect_ratio_override = -1;

    public signal void aspect_ratio_changed (Spice.AspectRatio ratio);
    public signal void reseted ();
    public signal void current_slide_changed (Slide slide);
    public signal void item_clicked (CanvasItem? item);
    public signal void new_slide_created (Slide slide);
    public signal void slides_sorted ();

    public Gtk.Stack slideshow {get; private set;}
    public Gee.ArrayList<Slide> slides {get; private set;}
    public bool making_new_slide = false;

    private Slide? slide_ = null;
    private Spice.CanvasItem? current_item_ = null;
    private Spice.AspectRatio current_ratio;

    public CanvasItem? current_item {
        get { return current_item_; }
        set {
            current_item_ = value;
            item_clicked (value);
        }
    }

    public Slide? current_slide {
        get { return slide_; }
        set {
            if (slide_ != null) {
                slide_.canvas.unselect_all ();
            }

            if (!window.is_fullscreen && current_slide != null) {
                current_slide.reload_preview_data ();
            }

            if (slides.contains (value)) {
                slide_ = value;
                current_item = null;
                slideshow.set_visible_child (value.canvas);
                current_slide_changed (value);
                value.load_slide ();
            }
        }
    }

    public SlideManager () {
        slides = new Gee.ArrayList<Slide> ();
        slideshow = new Gtk.Stack ();
        slideshow.homogeneous = false;
    }

    public void reset () {
        slide_ = null;

        foreach (var slide in slides) {
            slideshow.remove (slide.canvas);
            slide.destroy ();
        }

        slides.clear ();
        ImageHandler.FILE_ID = 0;

        reseted ();
    }

    public uint slide_count () {
        uint slide_count = 0;

        foreach (var slide in slides) {
            if (slide.visible) {
                slide_count++;
            }
        }

        return slide_count;
    }

    public string serialise () {
        string data = "";

        foreach (var slide in slides) {
            if (slide.visible) {
                data = data + (data != "" ? "," + slide.serialise () : slide.serialise ());
            }
        }

        var current_slide_index = current_slide != null ? slides.index_of (current_slide) : 0;
        return """{"current-slide":%d, "aspect-ratio":%d, "slides": [%s]}""".printf (current_slide_index, current_ratio, data);
    }

    public void load_data (string data) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (data);

            var root_object = parser.get_root ().get_object ();
            var slides_array = root_object.get_array_member ("slides");

            var ratio = (int) root_object.get_int_member ("aspect-ratio");

            if (aspect_ratio_override != -1) {
                ratio = aspect_ratio_override;
                aspect_ratio_override = -1;
            }

            current_ratio = Spice.AspectRatio.get_mode (ratio);
            aspect_ratio_changed (current_ratio);

            foreach (var slide_object in slides_array.get_elements ()) {
                new_slide (slide_object.get_object ());
            }

            var position = (int) root_object.get_int_member ("current-slide");
            if (slides.size > position && position >= 0) {
                current_slide = slides[position];
                current_slide.reload_preview_data ();
            } else {
                current_slide = slides[0];
            }
        } catch (Error e) {
            error ("Error loading file: %s", e.message);
        }
    }

    public void move_down (Slide slide) {
        var index = slides.index_of (slide);

        var next_slide = get_next_slide (slide);
        if (next_slide != null) {
            var next_index = slides.index_of (next_slide);

            slides.set (next_index, slide);
            slides.set (index, next_slide);

            slides_sorted ();
        }
    }

    public void move_up (Slide slide) {
        var index = slides.index_of (slide);

        var previous_slide = get_previous_slide (slide);
        if (previous_slide != null) {
            var previous_index = slides.index_of (previous_slide);

            slides.set (previous_index, slide);
            slides.set (index, previous_slide);

            slides_sorted ();
        }
    }

    public void previous_slide () {
        var previous_slide = get_previous_slide (current_slide);

        if (previous_slide != null) {
            current_slide = previous_slide;
        }
    }

    public void next_slide () {
        var next_slide = get_next_slide (current_slide);

        if (next_slide != null) {
            current_slide = next_slide;
        } else {
            // TODO: Show end of presentation slide
            window.unfullscreen ();
        }
    }

    private Slide? get_next_slide (Slide current) {
        Slide? next_slide = null;
        bool found = false;
        int n = 1;

        do {
            var next_index = slides.index_of (current) + n++;
            if (next_index < slides.size) {
                var slide = slides.get (next_index);
                if (slide.visible) {
                    next_slide = slide;
                    found = true;
                }
            } else {
                found = true;
            }
        } while (!found);

        return next_slide;
    }

    private Slide? get_previous_slide (Slide current) {
        Slide? previous_slide = null;
        bool found = false;
        int n = 1;

        do {
            var previous_index = slides.index_of (current) - n++;
            if (previous_index >= 0 && previous_index < slides.size) {
                var slide = slides.get (previous_index);
                if (slide.visible) {
                    previous_slide = slide;
                    found = true;
                }
            }

            if (previous_index < 0) {
                found = true;
            }
        } while (!found);

        return previous_slide;
    }

    private bool propagating_ratio = false;

    public Slide new_slide (Json.Object? save_data = null, bool undoable_action = false) {
        Slide slide = new Slide (save_data);

        slide.canvas.item_clicked.connect ((item) => {
            current_item = item;
        });

        slide.canvas.next_slide.connect (() => {
            next_slide ();
        });

        slide.canvas.previous_slide.connect (() => {
            previous_slide ();
        });

        slide.canvas.ratio_changed.connect ((new_ratio) => {
            if (this.propagating_ratio) return;
            this.propagating_ratio = true;

            foreach (var s in slides) {
                if (s.visible) {
                    s.canvas.current_ratio = new_ratio;
                    var w = slide.canvas.get_allocated_width ();
                    var h = slide.canvas.get_allocated_height ();

                    // Force size
                    s.canvas.set_size_request (w, h);
                    s.canvas.set_size_request (500, 380);
                }
            }

            this.propagating_ratio = false;
        });

        if (undoable_action) {
            slide.visible = false;
            var action = new Spice.Services.HistoryManager.HistoryAction<Slide,bool>.slide_changed (slide, "visible");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action, true);
            slide.visible = true;
        }

        slides.add (slide);
        slideshow.add (slide.canvas);
        slideshow.show_all ();

        new_slide_created (slide);

        if (undoable_action) {
            current_slide = slide;
        }

        slide.visible_changed.connect ((visible) => {
            if (visible) {
                this.current_slide = slide;
            } else {
                var next_slide = get_next_slide (slide);

                if (next_slide == null) {
                    next_slide = get_previous_slide (slide);
                }

                if (next_slide != null) {
                    this.current_slide = next_slide;
                }
            }
        });

        return slide;
    }

    public CanvasItem? request_new_item (Spice.HeaderButton type) {
        CanvasItem? item = null;

        if (type == HeaderButton.TEXT) {
            item = new TextItem (current_slide.canvas);
        } else if (type == HeaderButton.IMAGE) {
            var file = Spice.Services.FileManager.open_image ();
            if (file != null && file.query_exists ()) {
                item = new ImageItem.from_file (current_slide.canvas, file);
            }
        } else if (type == HeaderButton.SHAPE) {
            item = new ColorItem (current_slide.canvas);
        }

        if (item != null) {
            current_slide.canvas.add_item (item, true);
        }

        return item;
    }

    public Slide? checkpoint = null;
    public void jump_to_checkpoint () {
        if (!window.is_fullscreen) return;

        if (checkpoint != null) {
            var temp = checkpoint;
            checkpoint = current_slide;
            current_slide = temp;
        }
    }

    public void set_checkpoint () {
        if (!window.is_fullscreen) return;

        checkpoint = current_slide;
    }
}

