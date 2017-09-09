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
        return color1.color;
    }

    public string get_2 () {
        return color2.color;
    }

    public string get_preview () {
        return preview.color;
    }

    public static void add_tests () {
        Test.add_func ("/ColorPicker/SetGradient-first-opacity", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RGBA, BLUE);

            test.color = color;
            assert (test.get_1 () == ColorButtonTest.RGBA);
            assert (test.get_2 () == ColorButtonTest.BLUE);
            assert (test.get_preview () == color);
        });

        Test.add_func ("/ColorPicker/SetGradient-second-opacity", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RED, RGBA);

            test.color = color;
            assert (test.get_1 () == ColorButtonTest.RED);
            assert (test.get_2 () == ColorButtonTest.RGBA);
            assert (test.get_preview () == color);
        });

        Test.add_func ("/ColorPicker/SetGradient-both-with-opacity", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RGBA, RGBA);

            test.color = color;
            assert (test.get_1 () == ColorButtonTest.RGBA);
            assert (test.get_2 () == ColorButtonTest.RGBA);
            assert (test.get_preview () == color);
        });

        Test.add_func ("/ColorPicker/SetGradient-rgb-rgba1", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RGB, RGBA);

            test.color = color;
            assert (test.get_1 () == ColorButtonTest.RGB);
            assert (test.get_2 () == ColorButtonTest.RGBA);
            assert (test.get_preview () == color);
        });

        Test.add_func ("/ColorPicker/SetGradient-rgb-rgba2", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RGBA, RGB);

            test.color = color;
            assert (test.get_1 () == ColorButtonTest.RGBA);
            assert (test.get_2 () == ColorButtonTest.RGB);
            assert (test.get_preview () == color);
        });

        Test.add_func ("/ColorPicker/SetGradient-rgb", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RGB, RGB);

            test.color = color;
            assert (test.get_1 () == ColorButtonTest.RGB);
            assert (test.get_2 () == ColorButtonTest.RGB);
            assert (test.get_preview () == color);
        });

        Test.add_func ("/ColorPicker/opacity-test", () => {
            var test = new ColorButtonTest ();

            test.color = RGBA;
            assert (test.get_1 () == RGBA);
            assert (test.get_2 () == RGBA);
            assert (test.get_preview () == RGBA);
        });

        Test.add_func ("/ColorPicker/rgb", () => {
            var test = new ColorButtonTest ();

            test.color = RGB;
            assert (test.get_1 () == RGB);
            assert (test.get_2 () == RGB);
            assert (test.get_preview () == RGB);
        });

        Test.add_func ("/ColorPicker/SetAll", () => {
            var test = new ColorButtonTest ();

            test.color = RED;
            assert (test.get_1 () == RED);
            assert (test.get_2 () == RED);
            assert (test.get_preview () == RED);
        });

        Test.add_func ("/ColorPicker/SetGradient", () => {
            var test = new ColorButtonTest ();

            var color = "linear-gradient(to bottom, %s 0%, %s 100%)".printf (RED, BLUE);

            test.color = color;
            assert (test.get_1 () == ColorButtonTest.RED);
            assert (test.get_2 () == ColorButtonTest.BLUE);
            assert (test.get_preview () == color);
        });

        Test.add_func ("/ColorPicker/SetOneColor", () => {
            var test = new ColorButtonTest ();
            assert (test.get_preview () == DEFAULT);
            assert (test.get_1 () == DEFAULT);
            assert (test.get_2 () == DEFAULT);
            assert (test.get_preview () == DEFAULT);

            var result = "linear-gradient(to bottom, %s 0%, %s 100%)";

            // Setting first color
            test.color_selector = 1;
            test.set_color_smart (RED, true);

            assert (test.get_1 () == RED);
            assert (test.get_2 () == DEFAULT);
            assert (test.get_preview () == result.printf (RED, DEFAULT));

            // Setting second color
            test.color_selector = 2;
            test.set_color_smart (BLUE, true);

            assert (test.get_1 () == RED);
            assert (test.get_2 () == BLUE);
            assert (test.get_preview () == result.printf (RED, BLUE));

            // Setting both color
            test.color_selector = 3;
            test.set_color_smart (DEFAULT, true);

            assert (test.get_1 () == DEFAULT);
            assert (test.get_2 () == DEFAULT);
            assert (test.get_preview () == DEFAULT);
        });
    }

    public static int main (string[] args) {
        Gtk.init (ref args);
        Test.init (ref args);

        ColorButtonTest.add_tests ();
        return Test.run ();
    }
}
