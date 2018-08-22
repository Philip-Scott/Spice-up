/*
* Copyright (c) 2018 Felipe Escoto (https://github.com/Philip-Scott/Spice-up)
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

protected class Spice.ColorButton : Gtk.Button {
    protected Gtk.EventBox surface;

    public string _color = "none";
    public string color {
        get {
            return _color;
        } set {
            if (value != "") {
                _color = value;
                style ();
            }
        }
    }

    public ColorButton (string color) {
        Object (color: color);
    }

    construct {
        surface = new Gtk.EventBox ();
        surface.set_size_request (24, 24);
        surface.get_style_context ().add_class ("colored");
        get_style_context ().add_class ("color-button");
        Utils.set_style (this, STYLE_CSS);

        var background = new Gtk.EventBox ();
        background.get_style_context ().add_class ("checkered");
        Utils.set_style (background, CHECKERED_CSS);

        can_focus = false;
        add (background);
        background.add (surface);
    }

    public void set_size (int x, int y) {
        surface.set_size_request (x, y);
    }

    public new void style () {
        Utils.set_style (surface, SURFACE_STYLE_CSS.printf (_color));
    }

    private const string STYLE_CSS = """
        .color-button.flat {
            border: none;
            padding: 0;
        }
    """;

    private const string CHECKERED_CSS = """
        .checkered {
            background-image: url('resource:///com/github/philip-scott/spice-up/patterns/ps-neutral.png');
        }
    """;

    private const string SURFACE_STYLE_CSS = """
        .colored {
            background: %s;
        }

        .color-button:active .colored {
            opacity: 0.9;
        }

        .color-button:focus .colored {
            border: 1px solid black;
        }
    """;
}