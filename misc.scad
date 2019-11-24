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