// I guess I should mention that while this method has been 90% overhauled, its essence originally came from inside the nema17_stepper module of https://github.com/revarbat/BOSL
module flattedShaft(h=1, r=0.5, center=false) {
  translate([0,0,-0.5*h*(center?1:0)])
  difference() {
    cylinder(h=h, r=r);
    translate([(h+r)/2+r-0.5,0,h/2]) { // I'm not totally convinced by the "always 0.5mm deep", but good enough for now
      cube(h+r, center=true);
    }
  }
}

flattedShaft(h=5,r=2.5, $fn=60);

// Make a block go away.  Useful for debugging probably.
module skip() {
  scale([0,0,0]) { // Just in case
    difference() {
      children();
      children();
    }
  }
}
