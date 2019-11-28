$FOREVER = 1000;
$EPS=1e-300;

// I guess I should mention that while this method has been 90% overhauled, its essence originally came from inside the nema17_stepper module of https://github.com/revarbat/BOSL
module flattedShaft(h=5, r=2.5, flat_depth=0.5, center=false) {
  translate([0,0,-0.5*h*(center?1:0)])
  difference() {
    cylinder(h=h, r=r);
    translate([(h+r)/2+r-flat_depth,0,h/2]) { // I'm not totally convinced by the "always 0.5mm deep", but good enough for now
      cube(h+r, center=true);
    }
  }
}

// Make a block go away.  Useful for debugging probably.
// EXCEPT that I've discovered that * does that, but better.
module skip() {
  scale([0,0,0]) { // Just in case
    difference() {
      children();
      children();
    }
  }
}

// Note that this is kinda slow
module perforate(nx=100,ny=100,size=1,diam=0.5) { //TODO Add dir
  difference() {
    children();
    for (x = [-nx/2:nx/2]) {
      translate([x*2*diam,0,0])
        cube([diam,$FOREVER,$FOREVER],center=true);
    }
    for (y = [-ny/2:ny/2]) {
      translate([0,y*2*diam,0])
        cube([$FOREVER,diam,$FOREVER],center=true);
    }
  }
}

// Useful for minkowski 2D and 3D shapes together
module flat3d() {
  linear_extrude(height=$EPS)
    children();
}


//// Octants
// Useful for cutting away sections of the...everything

// Pick a dir, then use -1 or 1 ; e.g. [1,0,0], [0,0,-1], etc.
module halfSpace(dir=[0,0,0]) {
    translate(dir*($FOREVER/2)) cube($FOREVER,center=true);
}

module OXm(delta=[0,0,0]) {translate(delta) halfSpace([-1,0,0]);}
module OXp(delta=[0,0,0]) {translate(delta) halfSpace([+1,0,0]);}
module OYm(delta=[0,0,0]) {translate(delta) halfSpace([0,-1,0]);}
module OYp(delta=[0,0,0]) {translate(delta) halfSpace([0,+1,0]);}
module OZm(delta=[0,0,0]) {translate(delta) halfSpace([0,0,-1]);}
module OZp(delta=[0,0,0]) {translate(delta) halfSpace([0,0,+1]);}

module OXmYm(delta=[0,0,0]) {translate(delta) halfSpace([-1,-1,0]);}
module OXmYp(delta=[0,0,0]) {translate(delta) halfSpace([-1,+1,0]);}
module OXpYm(delta=[0,0,0]) {translate(delta) halfSpace([+1,-1,0]);}
module OXpYp(delta=[0,0,0]) {translate(delta) halfSpace([+1,+1,0]);}
module OXmZm(delta=[0,0,0]) {translate(delta) halfSpace([-1,0,-1]);}
module OXmZp(delta=[0,0,0]) {translate(delta) halfSpace([-1,0,+1]);}
module OXpZm(delta=[0,0,0]) {translate(delta) halfSpace([+1,0,-1]);}
module OXpZp(delta=[0,0,0]) {translate(delta) halfSpace([+1,0,+1]);}
module OYmZm(delta=[0,0,0]) {translate(delta) halfSpace([0,-1,-1]);}
module OYmZp(delta=[0,0,0]) {translate(delta) halfSpace([0,-1,+1]);}
module OYpZm(delta=[0,0,0]) {translate(delta) halfSpace([0,+1,-1]);}
module OYpZp(delta=[0,0,0]) {translate(delta) halfSpace([0,+1,+1]);}

module OXmYmZm(delta=[0,0,0]) {translate(delta) halfSpace([-1,-1,-1]);}
module OXmYmZp(delta=[0,0,0]) {translate(delta) halfSpace([-1,-1,+1]);}
module OXmYpZm(delta=[0,0,0]) {translate(delta) halfSpace([-1,+1,-1]);}
module OXmYpZp(delta=[0,0,0]) {translate(delta) halfSpace([-1,+1,+1]);}
module OXpYmZm(delta=[0,0,0]) {translate(delta) halfSpace([+1,-1,-1]);}
module OXpYmZp(delta=[0,0,0]) {translate(delta) halfSpace([+1,-1,+1]);}
module OXpYpZm(delta=[0,0,0]) {translate(delta) halfSpace([+1,+1,-1]);}
module OXpYpZp(delta=[0,0,0]) {translate(delta) halfSpace([+1,+1,+1]);}


//// Pin joiner

/*
WARNING!  I'm experiencing some bug with OpenSCAD atm, where
depending on which order you render the pin alone vs. the
m/f components, the handle is erroneously subtracted from the
m/f components.  If this happens to you, flush your caches, and try
rendering the pin separately or after the other components.
...I'm also experiencing weird problems where old things keep getting
rendered until I clear the cache.  Dunno if that's something triggered
by this particular file or what.

*OTHER* WARNING!  Do note that the pins can snap off, leaving your piece
rather difficult to disassemble / finish assembling.
*/

DEF_WSLOP = 0.4;
DEF_PHSLOP = 1;

PIN_HEIGHT_FACTOR = 5/6;
PIN_DEPTH_FACTOR = 0.4;

/** Note that slop is applied once in the relevant axis, but shared between the male and female components.  0.5 width_slop makes the male plug 0.25mm thinner and the female socket 0.25mm wider.  However, pieces are still positioned as if they had no slop. */
module pinJoiner(depth=5,width=5,height=15,width_slop=DEF_WSLOP,pin_height_slop=DEF_PHSLOP,bottomOverhang=true) {
    difference() {
        translate([width_slop/4,0,0]) cube([width - width_slop/2,depth,height]);
        translate([-1,0,height-depth]) rotate([45,0,0]) cube($FOREVER);
        translate([0,-depth*PIN_DEPTH_FACTOR/2 + depth/2,height/3+(height/3-(PIN_HEIGHT_FACTOR*height/3)-pin_height_slop/4)])
            pinJoinerPin(depth*PIN_DEPTH_FACTOR,width*3,PIN_HEIGHT_FACTOR*height/3 + pin_height_slop/2,pin_height_slop=0,handle=false);
        if (bottomOverhang) {
            translate([-1,0,depth]) rotate([-135,0,0]) cube($FOREVER);
        }
    }
}

// Cut this out of the receiving area
// Note that the width slop is not applied to the length of the pin.
module pinJoinerCutout(depth=5,width=5,height=15,width_slop=DEF_WSLOP,pinLengthXP=5,pinLengthXM=15,wedgeAngle=60,pin_height_slop=DEF_PHSLOP,bottomOverhang=true) {
    difference() {
        translate([-width_slop/4,0,0]) cube([width + width_slop/2,depth,height]);
        translate([-1,0,height-depth]) rotate([45,0,0]) cube($FOREVER);
        if (bottomOverhang) {
            translate([-1,0,depth]) rotate([-135,0,0]) cube($FOREVER);
        }
    }
    translate([width,-depth*PIN_DEPTH_FACTOR/2 + depth/2,height/3+(height/3-(PIN_HEIGHT_FACTOR*height/3))-pin_height_slop/4])
        pinJoinerPin(depth*PIN_DEPTH_FACTOR,pinLengthXP,PIN_HEIGHT_FACTOR*height/3 + pin_height_slop/2,pin_height_slop=0,wedgeAngle=wedgeAngle,handle=false);
    translate([0,-depth*PIN_DEPTH_FACTOR/2 + depth/2,height/3+(height/3-(PIN_HEIGHT_FACTOR*height/3))-pin_height_slop/4])
        mirror([1,0,0])
            pinJoinerPin(depth*PIN_DEPTH_FACTOR,pinLengthXM,PIN_HEIGHT_FACTOR*height/3 + pin_height_slop/2,pin_height_slop=0,wedgeAngle=wedgeAngle,handle=false);
}

module pinJoinerPin(depth=5*PIN_DEPTH_FACTOR,width=15,height=5*PIN_HEIGHT_FACTOR,wedgeAngle=60,pin_height_slop=DEF_PHSLOP,handle=true) {
    translate([0,0,pin_height_slop/4]) {
        h0 = height-pin_height_slop/2;
        difference() {
            cube([width,depth,h0]);
            translate([-1,0,h0-depth]) rotate([45,0,0]) cube($FOREVER);
            translate([width,depth,-1]) rotate([0,0,-90-wedgeAngle]) cube($FOREVER);
        }
        if (handle) {
            translate([0,-h0+depth,0]) cube([depth,h0,h0]);
        }
    }
}

* union() { // Pin joiner example
    // Female
    difference() {
        translate([0,-10,0]) cube([15,10,19]);
        translate([2.5,-5,2]) pinJoinerCutout();
    }

    // Male
    translate([0,10,0]) union() {
        cube([10,10,19]);
        translate([2.5,-5,2]) pinJoiner();
    }

    // Pin
    translate([-5,3,5/3]) rotate([-90,0,0]) pinJoinerPin();
}