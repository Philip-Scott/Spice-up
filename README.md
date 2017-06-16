<div>
  <h1 align="center">Spice-up</h1>
  <h3 align="center">Create Simple and Beautiful presentations</h3>
</div>

<br/>

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.philip-scott.spice-up">
    <img src="get-on-appcenter.png" alt="AppCenter">
  </a>
</p>

<br/>

<p align="center">
    <img src="Screenshot.png" alt="Screenshot">
</p>


---
<br/>
<a href="https://www.bountysource.com/trackers/44752823-philip-scott-spice-up">
    <img src="https://www.bountysource.com/badge/tracker?tracker_id=44752823" alt="bountysource">
</a>
<br/>

Spice-up is a modern and intuitive desktop presentation app based upon [SpiceOfDesign's presentation concept](http://spiceofdesign.deviantart.com/art/New-Presentation-Concept-401767854). Built from the ground up for elementary OS, it gives you everything you need to create simple and beautiful presentations.

### Spice Presentations Look Amazing!
Images, shapes, Text, as well as beautiful background patterns and easy to make custom gradients!


### Coming Soon
- Animations and transitions
- Pre-defined layouts and themes
- And much more!


## Installation

<a href="https://appcenter.elementary.io/com.github.philip-scott.spice-up">![AppCenter](get-on-appcenter.png)</a>

On elementary OS? Hit the button to get Spice-Up!

#### Not on elementary?
You can install Spice-Up from a PPA. But be aware that your results may vary

    sudo add-apt-repository ppa:philip.scott/spice-up-daily
    sudo apt-get update
    sudo apt-get install spice-up

### Donations
Liked Spice-up? Would like to support its development of this app and more? Feel free to [leave a little tip :)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=WYD9ZJK6ZFUDQ) or support my work torwards a new feature over at [Bountysource](https://www.bountysource.com/trackers/44752823-philip-scott-spice-up). I'd really appreciate it :) 

## Dependencies
These dependencies must be present before building
 - `gtk+-3.0>=3.9.10`
 - `granite>=0.3`
 - `json-glib-1.0`
 - `gee-0.8`


## Building
```
mkdir build/ && cd build
cmake ..
make && sudo make install
```
