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
    public signal void item_clicked (CanvasItem? item);
    public signal void new_slide_created (Slide slide);
    public signal void slides_sorted ();

    public Gtk.Stack slideshow {get; private set;}
    public Gee.ArrayList<Slide> slides {get; private set;}

    private Slide? slide_ = null;

    public Slide? current_slide {
        get { return slide_; }
        set {
            if (slides.contains (value)) {
                slide_ = value;
                item_clicked (null);
                slideshow.set_visible_child (value.canvas);
            }
        }
    }

    public SlideManager () {
        slideshow = new Gtk.Stack ();
        slides = new Gee.ArrayList<Slide> ();
    }

    public string serialise () {
        string data = "";

        foreach (var slide in slides) {
            data = data + (data != "" ? "," + slide.serialise () : slide.serialise ());
        }

        return """{"slides": [%s]}""".printf (data);
    }

    public void load_data (string data) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (data);

            var root_object = parser.get_root ().get_object ();
            var slides_array = root_object.get_array_member ("slides");

            foreach (var slide_object in slides_array.get_elements ()) {
                new_slide (slide_object.get_object ());
            }
        } catch (Error e) {
            error ("Error loading file: %s", e.message);
        }

        if (slides.size == 0) new_slide ();
    }

    public void move_down (Slide slide) {
        var index = slides.index_of (slide);

        if (index + 1 < slides.size) {
            var slide_2 = slides.get (index + 1);

            slides.set (index + 1, slide);
            slides.set (index, slide_2);

            slides_sorted ();
        }
    }

    public void move_up (Slide slide) {
        var index = slides.index_of (slide);

        if (index - 1 >= 0) {
            var slide_2 = slides.get (index - 1);

            slides.set (index - 1, slide);
            slides.set (index, slide_2);

            slides_sorted ();
        }
    }

    public void next_slide () {
        var next_index = slides.index_of (current_slide) + 1;
        if (next_index < slides.size) {
            current_slide = slides.get (next_index);
        } else {
            // TODO: Show end of presentation slide
            window.unfullscreen ();
        }
    }

    public void new_slide (Json.Object? save_data = null) {
        Slide slide;

        slide = new Slide (save_data);

        slide.canvas.item_clicked.connect ((item) => {
            this.item_clicked (item);
        });

        slide.canvas.next_slide.connect (() => {
            next_slide ();
        });

        slides.add (slide);
        slideshow.add (slide.canvas);
        slideshow.show_all ();

        new_slide_created (slide);
        current_slide = slide;
        slide.position = slides.size;
    }

    public CanvasItem? request_new_item (Spice.HeaderButton type) {
        CanvasItem? item = null;

        if (type == HeaderButton.TEXT) {
            item = new TextItem (current_slide.canvas);
            item.load_data ();
            current_slide.canvas.add_item (item);
        } else if (type == HeaderButton.IMAGE) {
            var file = Spice.Services.FileManager.get_file_from_user (true);

            item = new ImageItem.from_file (current_slide.canvas, file);
            item = current_slide.canvas.add_item (item);
        } else if (type == HeaderButton.SHAPE) {
            item = new ColorItem (current_slide.canvas);
            item.load_data ();
            item = current_slide.canvas.add_item (item);
        }

        return item;
    }
}

