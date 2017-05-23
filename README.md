# Spice-up
[![Bountysource](https://www.bountysource.com/badge/tracker?tracker_id=44752823)](https://www.bountysource.com/trackers/44752823-philip-scott-spice-up)


### Create Simple and Beautiful presentations


Spice-up is a modern and intuitive desktop presentation app based upon [SpiceOfDesign's presentation concept](http://spiceofdesign.deviantart.com/art/New-Presentation-Concept-401767854). Built from the ground up for elementary OS, it gives you everything you need to create simple and beautiful presentations.


![screenshot](Screenshot.png)


### Spice Presentations Look Amazing!
Images, shapes, Text, as well as beautiful background patterns and easy to make custom gradients!


### Coming Soon
- Animations and transitions
- Pre-defined layouts and themes
- And much more!


### Donations
Liked Spice-up? Would like to support its development of this app and more? Feel free to [leave a little tip :)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=WYD9ZJK6ZFUDQ) or support my work torwards a new feature over at [Bountysource](https://www.bountysource.com/trackers/44752823-philip-scott-spice-up). I'd really appreciate it :) 


## Installation
If you are using **elementary OS Loki**, Spice-Up is <a href="appstream://com.github.philip-scott.spice-up">available directly from AppCenter</a>



PPA: philip.scott/spice-up-daily


```
sudo add-apt-repository ppa:philip.scott/spice-up-daily
sudo apt-get update
sudo apt-get install spice-up
```


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
