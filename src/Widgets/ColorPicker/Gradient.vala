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

public class Spice.Gradient : Object {
    private List<GradientStep> steps;
    public static Regex color_regex;
    public static Regex dir_regex;

    private string color;
    public string direction;

    static construct {
        try {
            color_regex = new Regex ("""(#[a-zA-Z0-9]{6}|#[a-zA-Z0-9]{3}|rgb\([0-9]{1,3},[0-9]{1,3},[0-9]{1,3}\)|rgba\([0-9]{1,3},[0-9]{1,3},[0-9]{1,3},[0-9\.]{1,}\))(\s[0-9]{1,}%)?""", 0);

            dir_regex = new Regex ("""gradient\(([a-z0-9\s]{1,}),""", 0);

        } catch (Error e) {
            error ("Regex failed: %s", e.message);
        }
    }

    public Gradient (string gradient) {
        color = gradient;
        steps = new List<GradientStep>();

        MatchInfo mi;

        if (color_regex.match (gradient, 0 , out mi)) {
            int pos_start = 0, pos_end = 0;

            try {
                do {
                    mi.fetch_pos (0, out pos_start, out pos_end);
                    if (pos_start == pos_end) {
                        break;
                    }

                    var step = new GradientStep (mi.fetch (1), mi.fetch (2));
                    steps.append (step);
                } while (mi.next ());
            } catch (Error e) {
                warning ("Could not find gradient steps: %s", e.message);
                return;
            }
        }

        if (dir_regex.match (gradient, 0 , out mi)) {
            int pos_start = 0, pos_end = 0;

            try {
                mi.fetch_pos (0, out pos_start, out pos_end);
                if (pos_start != pos_end) {
                    direction = mi.fetch (1);
                }
            } catch (Error e) {
                warning ("Could not find gradient direction: %s", e.message);
                return;
            }
        }
    }

    public string to_string () {
        string colors = "";

        steps.sort ((_a, _b) => {
            var a = int.parse (_a.percent.replace ("%", ""));
            var b = int.parse (_b.percent.replace ("%", ""));
            return (int) (a > b) - (int) (a < b);
        });
        steps.foreach ((step) => {
            colors += ", %s".printf (step.to_string ());
        });

        string result = @"linear-gradient($direction$colors)";
        return result;
    }

    public GradientStep get_color (int nth) {
        return steps.nth_data (nth);
    }

    public class GradientStep {
        public GradientStep (string _color, string _percent) {
            this.color = _color.strip ();
            this.percent = _percent.strip ();
        }

        public string color;
        public string percent;

        public string to_string () {
            return @"$color $percent".strip ();
        }
    }
}