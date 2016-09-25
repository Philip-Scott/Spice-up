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

    public Gtk.Stack slideshow {get; private set;}
    public Gee.ArrayList<Slide> slides {get; private set;}

    private Slide? slide_ = null;

    public Slide? current_slide {
        get { return slide_; }
        set {
            if (slides.contains (value)) {
                if (slide_ != null) {
                    slide_.load_data (slide_.serialise (), true);
                }

                slide_ = value;
                item_clicked (null);
                slideshow.set_visible_child (value.canvas);
            }
        }
    }

    public SlideManager () {
        slideshow = new Gtk.Stack ();
        slides = new Gee.ArrayList<Slide> ();
        new_slide (null, true);
    }

    public void new_slide (Json.Object? save_data = null, bool TEMP_TEST = false) {
        Slide slide;

        if (TEMP_TEST)
            slide = new Slide (save_data, null);
        else
            slide = new Slide (save_data, "");

        slide.canvas.item_clicked.connect ((item) => {
            this.item_clicked (item);
        });

        slides.add (slide);
        slideshow.add (slide.canvas);
        slideshow.show_all ();

        new_slide_created (slide);
        current_slide = slide;
    }

    public CanvasItem? request_new_item (Spice.HeaderButton type) {
        CanvasItem? item = null;

        if (type == HeaderButton.TEXT) {
            item = new TextItem (current_slide.canvas);
            item.load_data ();
            current_slide.canvas.add_item (item);
        } else if (type == HeaderButton.IMAGE) {

        } else if (type == HeaderButton.SHAPE) {
            item = new ColorItem (current_slide.canvas);
            item.load_data ();
            item = current_slide.canvas.add_item (item);
        }

        return item;
    }
}

