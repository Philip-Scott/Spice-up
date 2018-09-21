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

public class Spice.Widgets.CanvasToolbar : Spice.Widgets.Toolbar {
    public const string PATTERNS_DIR = "resource:///com/github/philip-scott/spice-up/patterns/";

    private Spice.ColorPicker canvas_gradient_background;
    private Spice.EntryCombo canvas_pattern;
    private Spice.EntryCombo transition;
    private SlideManager manager;

    public CanvasToolbar (SlideManager slide_manager) {
        this.manager = slide_manager;
    }
    construct {
        canvas_gradient_background = new Spice.ColorPicker.with_gradient (false);
        canvas_gradient_background.set_tooltip_text (_("Background color"));

        canvas_gradient_background.color_picked.connect ((s) => {
            if (selecting) return;
            var action = new Spice.Services.HistoryManager.HistoryAction<Canvas,string>.canvas_changed (this.manager.current_slide.canvas, "background-color");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_properties ();
        });

        canvas_pattern = new Spice.EntryCombo (true, true);
        canvas_pattern.set_tooltip_text (_("Background pattern"));
        canvas_pattern.editable = false;

        canvas_pattern.add_entry (PATTERNS_DIR + "3px-tile.png", _("3px tile"));
        canvas_pattern.add_entry (PATTERNS_DIR + "45-degree-fabric-dark.png", _("Fabric dark"));
        canvas_pattern.add_entry (PATTERNS_DIR + "45-degree-fabric-light.png", _("Fabric light"));
        canvas_pattern.add_entry (PATTERNS_DIR + "batthern.png", _("Batthern"));
        canvas_pattern.add_entry (PATTERNS_DIR + "beige-paper.png", _("Beige paper"));
        canvas_pattern.add_entry (PATTERNS_DIR + "black-linen.png", _("Black linen"));
        canvas_pattern.add_entry (PATTERNS_DIR + "bright-squares.png", _("Bright squares"));
        canvas_pattern.add_entry (PATTERNS_DIR + "diamond-upholstery.png", _("Diamond Upholstery"));
        canvas_pattern.add_entry (PATTERNS_DIR + "flowers.png", _("Flowers"));
        canvas_pattern.add_entry (PATTERNS_DIR + "hexellence.png", _("Hexellence"));
        canvas_pattern.add_entry (PATTERNS_DIR + "gplay.png", _("Gplay"));
        canvas_pattern.add_entry (PATTERNS_DIR + "inspiration-geometry.png", _("Geometry"));
        canvas_pattern.add_entry (PATTERNS_DIR + "dark-geometric.png", _("Dark geometric"));
        canvas_pattern.add_entry (PATTERNS_DIR + "light-wool.png", _("Light wool"));
        canvas_pattern.add_entry (PATTERNS_DIR + "ps-neutral.png", _("Neutral squares"));
        canvas_pattern.add_entry (PATTERNS_DIR + "silver-scales.png", _("Silver scales"));
        canvas_pattern.add_entry (PATTERNS_DIR + "subtle-freckles.png", _("Subtle grid"));
        canvas_pattern.add_entry (PATTERNS_DIR + "subtle-grey.png", _("Subtle squares"));
        canvas_pattern.add_entry (PATTERNS_DIR + "xv.png", _("XV"));
        canvas_pattern.add_entry ("", _(" None"));

        canvas_pattern.activated.connect (() => {
            var action = new Spice.Services.HistoryManager.HistoryAction<Canvas,string>.canvas_changed (this.manager.current_slide.canvas, "background-pattern");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_properties ();
        });

        transition = new Spice.EntryCombo (true, false);
        transition.set_tooltip_text (_("Transition"));
        transition.editable = false;

        transition.add_entry (((int) Gtk.StackTransitionType.NONE).to_string (), _("No Transition"));
        transition.add_entry (((int) Gtk.StackTransitionType.CROSSFADE).to_string (), _("Crossfade"));
        transition.add_entry (((int) Gtk.StackTransitionType.SLIDE_RIGHT).to_string (), _("Slide right"));
        transition.add_entry (((int) Gtk.StackTransitionType.SLIDE_LEFT).to_string (), _("Slide left"));
        transition.add_entry (((int) Gtk.StackTransitionType.SLIDE_UP).to_string (), _("Slide up"));
        transition.add_entry (((int) Gtk.StackTransitionType.SLIDE_DOWN).to_string (), _("Slide down"));
        transition.add_entry (((int) Gtk.StackTransitionType.OVER_UP).to_string (), _("Cover up"));
        transition.add_entry (((int) Gtk.StackTransitionType.OVER_DOWN).to_string (), _("Cover down"));
        transition.add_entry (((int) Gtk.StackTransitionType.OVER_LEFT).to_string (), _("Cover left"));
        transition.add_entry (((int) Gtk.StackTransitionType.OVER_RIGHT).to_string (), _("Cover right"));
        transition.add_entry (((int) Gtk.StackTransitionType.UNDER_UP).to_string (), _("Uncover up"));
        transition.add_entry (((int) Gtk.StackTransitionType.UNDER_DOWN).to_string (), _("Uncover down"));
        transition.add_entry (((int) Gtk.StackTransitionType.UNDER_LEFT).to_string (), _("Uncover left"));
        transition.add_entry (((int) Gtk.StackTransitionType.UNDER_RIGHT).to_string (), _("Uncover right"));

        transition.activated.connect (() => {
            var action = new Spice.Services.HistoryManager.HistoryAction<Slide, Gtk.StackTransitionType>.canvas_changed (this.manager.current_slide, "transition");
            Spice.Services.HistoryManager.get_instance ().add_undoable_action (action);
            update_properties ();
        });

        add (canvas_gradient_background);
        add (canvas_pattern);
        add (transition);
    }

    protected override void item_selected (Spice.CanvasItem? item, bool new_item = false) {
        if (new_item) {
            update_properties ();
            return;
        }

        transition.text = ((int) manager.current_slide.transition).to_string ();
        canvas_gradient_background.color = manager.current_slide.canvas.background_color;
        canvas_pattern.text = manager.current_slide.canvas.background_pattern;
    }

    public override void update_properties () {
        manager.current_slide.transition = (Gtk.StackTransitionType) int.parse (transition.text);
        manager.current_slide.canvas.background_pattern = canvas_pattern.text;
        manager.current_slide.canvas.background_color = canvas_gradient_background.color;
        manager.current_slide.canvas.style ();
    }
}
