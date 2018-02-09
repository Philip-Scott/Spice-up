/*
* Copyright (c) 2017 Felipe Escoto
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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

public class ColorButtonTest : Spice.ColorPicker {
    const string RED = "#F00";
    const string BLUE = "#0000FF";
    const string DEFAULT = "white";
    const string RGBA = "rgba(255,0,25,0.65432)";
    const string RGB = "rgb(255,0,25)";

    construct {
        gradient = true;
    }

    public string get_1 () {
        return gradient_editor.gradient.get_color (0).color;
    }

    public string get_2 () {
        return gradient_editor.gradient.get_color (1).color;
    }

    public string get_preview () {
        return gradient_editor.make_gradient ();
    }

    public static void assert_string (string a, string b) {
        if (a != b) {
            warning (@"$a != $b");
            assert (a == b);
        }
        info (@"$a == $b");
    }

    public static void add_tests () {
        Test.add_func ("/ColorPicker/SetGradient-first-opacity", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RGBA, BLUE);

            test.color = color;
            assert_string (test.get_1 (), ColorButtonTest.RGBA);
            assert_string (test.get_2 (), ColorButtonTest.BLUE);
            assert_string (test.get_preview (), color);
        });

        Test.add_func ("/ColorPicker/SetGradient-second-opacity", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RED, RGBA);

            test.color = color;
            assert_string (test.get_1 (), ColorButtonTest.RED);
            assert_string (test.get_2 (), ColorButtonTest.RGBA);
            assert_string (test.get_preview (), color);
        });

        Test.add_func ("/ColorPicker/SetGradient-both-with-opacity", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RGBA, RGBA);

            test.color = color;
            assert_string (test.get_1 (), ColorButtonTest.RGBA);
            assert_string (test.get_2 (), ColorButtonTest.RGBA);
            assert_string (test.get_preview (), color);
        });

        Test.add_func ("/ColorPicker/SetGradient-rgb-rgba1", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RGB, RGBA);

            test.color = color;
            assert_string (test.get_1 (), ColorButtonTest.RGB);
            assert_string (test.get_2 (), ColorButtonTest.RGBA);
            assert_string (test.get_preview (), color);
        });

        Test.add_func ("/ColorPicker/SetGradient-rgb-rgba2", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RGBA, RGB);

            test.color = color;
            assert_string (test.get_1 (), ColorButtonTest.RGBA);
            assert_string (test.get_2 (), ColorButtonTest.RGB);
            assert_string (test.get_preview (), color);
        });

        Test.add_func ("/ColorPicker/SetGradient-rgb", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RGB, RGB);

            test.color = color;
            assert_string (test.get_1 (), ColorButtonTest.RGB);
            assert_string (test.get_2 (), ColorButtonTest.RGB);
            assert_string (test.get_preview (), color);
        });

        Test.add_func ("/ColorPicker/opacity-test", () => {
            var test = new ColorButtonTest ();

            test.color = RGBA;
            assert_string (test.get_1 (), RGBA);
            assert_string (test.get_2 (), RGBA);
            assert_string (test.get_preview (), "linear-gradient(to bottom, rgba(255,0,25,0.65432) 0%, rgba(255,0,25,0.65432) 100%)");
        });

        Test.add_func ("/ColorPicker/rgb", () => {
            var test = new ColorButtonTest ();

            test.color = RGB;
            assert_string (test.get_1 (), RGB);
            assert_string (test.get_2 (), RGB);
            assert_string (test.get_preview (), "linear-gradient(to bottom, rgb(255,0,25) 0%, rgb(255,0,25) 100%)");
        });

        Test.add_func ("/ColorPicker/SetAll", () => {
            var test = new ColorButtonTest ();

            test.color = RED;
            assert_string (test.get_1 (), RED);
            assert_string (test.get_2 (), RED);
            assert_string (test.get_preview (), "linear-gradient(to bottom, #F00 0%, #F00 100%)");
        });

        Test.add_func ("/ColorPicker/SetGradient", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RED, BLUE);

            test.color = color;
            assert_string (test.get_1 (), ColorButtonTest.RED);
            assert_string (test.get_2 (), ColorButtonTest.BLUE);
            assert_string (test.get_preview (), color);
        });

        Test.add_func ("/ColorPicker/SetOneColor", () => {
            var test = new ColorButtonTest ();
            test.fake_gradient_mode (true);

            var result = "linear-gradient(to bottom, %s 0%, %s 100%)";

            // Setting first color
            test.gradient_editor.selected_step = test.gradient_editor.gradient.get_color (0);
            test.set_color_smart (RED, true);

            assert_string (test.get_1 (), RED);
            assert_string (test.get_2 (), DEFAULT);
            assert_string (test.get_preview (), result.printf (RED, DEFAULT));

            // Setting second color
            test.gradient_editor.selected_step = test.gradient_editor.gradient.get_color (1);
            test.set_color_smart (BLUE, true);

            assert_string (test.get_1 (), RED);
            assert_string (test.get_2 (), BLUE);
            assert_string (test.get_preview (), result.printf (RED, BLUE));

            // Setting both color
            test.fake_gradient_mode (false);
            test.gradient_editor.selected_step = test.gradient_editor.gradient.get_color (0);
            test.set_color_smart (DEFAULT, true);

            assert_string (test.get_1 (), DEFAULT);
            assert_string (test.get_2 (), DEFAULT);
            assert_string (test.get_preview (), result.printf (DEFAULT, DEFAULT));
        });
    }

    public void fake_gradient_mode (bool state) {
        gradient_revealer.reveal_child = state;
    }

    public static int main (string[] args) {
        Gtk.init (ref args);
        Test.init (ref args);

        ColorButtonTest.add_tests ();
        return Test.run ();
    }
}
