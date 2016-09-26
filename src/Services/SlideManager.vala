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
                    var data = slide_.serialise ();
                    var parser = new Json.Parser ();
                    parser.load_from_data (data);

                    slide_.load_data (parser.get_root ().get_object (), true);
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

        load_data (TESTING_DATA);
    }

    public string serialise () {
        string data = "";

        foreach (var slide in slides) {
            data = data + (data != "" ? "," + slide.serialise () : slide.serialise ());
        }

        return """{"slides": [%s]}""".printf (data);
    }

    public void load_data (string data, bool preview_only = false) {
        var parser = new Json.Parser ();
        parser.load_from_data (data);

        var root_object = parser.get_root ().get_object ();
        var slides_array = root_object.get_array_member ("slides");

        foreach (var slide_object in slides_array.get_elements ()) {
            new_slide (slide_object.get_object ());
        }
    }

    public void new_slide (Json.Object? save_data = null) {
        Slide slide;

        slide = new Slide (save_data);

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

    private const string TESTING_DATA = """
    {
"slides": [{
	"background_color": "red",
	"items": [{
		"x": -313,
		"y": -76,
		"w": 2203,
		"h": 1731,

		"type": "color",
		"background_color": "rgb(114,159,207)"

	}, {
		"x": -354,
		"y": 970,
		"w": 1925,
		"h": 122,

		"type": "color",
		"background_color": "rgb(252,233,79)"

	}, {
		"x": -280,
		"y": 458,
		"w": 1897,
		"h": 336,

		"type": "text",
		"text": "New Presentation",
		"font": "Raleway Medium 10",
		"color": "rgb(255,255,255)",
		"font-size": 42

	}, {
		"x": -339,
		"y": 702,
		"w": 902,
		"h": 300,

		"type": "text",
		"text": "By Felipe Escoto",
		"font": "Open Sans",
		"color": "rgb(255,255,255)",
		"font-size": 18

	}]
}, {
    "background_color": "red",
	"items": [{}]
}]
}
        """;
}

