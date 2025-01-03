$FOREVER = 2000;
$EPS=1e-300;
INCH = 25.4;

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

function sqr(x) = x*x;

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
module perforate(nx=100,ny=100,t=0.5,t0=0.5) { //TODO Add dir
  intersection() {
    children();
    union() {
      for (x = [-nx/2:nx/2]) {
        translate([x*(t+t0),0,0])
          cube([t,$FOREVER,$FOREVER],center=true);
      }
      for (y = [-ny/2:ny/2]) {
        translate([0,y*(t+t0),0])
          cube([$FOREVER,t,$FOREVER],center=true);
      }
    }
  }
}


// Note that this is kinda slow...and buggy
module radialPerforate(d=10,a=45,t=5,t0=5,h=100) {
  intersection() {
    children();
    union() {
      n = (2*PI*(d/2))/(t+t0);
      i = 0;
      for (i = [0:n-1]) {
      //for (i = [0]) {
        ai = 360*i/n;
        rz(ai) cmirror([1,0,0]) linear_extrude(height=h,twist=6*h,slices=100,center=true) ty(d/2) square([t,d],center=true);
      }
    }
  }
}

//radialPerforate(t=5,t0=5) {
//    difference() {
//        cylinder(d=105,h=40,center=true);
//        cylinder(d=9.5,h=1000,center=true);
//    }
//}

// Useful for minkowski 2D and 3D shapes together
module flat3d(center=false) {
  linear_extrude(height=$EPS,center=center)
    children();
}

module shell(center_on_border=false,all_sides=true,t=1) {
    if (center_on_border) {
        difference() {
            minkowski() {
                children();
                if (all_sides) {
                    sphere(d=t);
                } else {
                    flat3d(center=true) circle(d=t);
                }
            }
            difference() {
                children();
                minkowski() {
                    shell(center_on_border=false,all_sides=all_sides,t=t/2) {
                        children();
                    }
                    if (all_sides) {
                        sphere(d=t);
                    } else {
                        flat3d(center=true) circle(d=t);
                    }
                }
            }
        }
    } else {
        difference() {
            minkowski() {
                children();
                if (all_sides) {
                    sphere(d=t*2);
                } else {
                    flat3d(center=true) circle(d=t*2);
                }
            }
            children();
        }
    }
}

module shell2d(center_on_border=false,t=1) {
    if (center_on_border) {
        difference() {
            minkowski() {
                children();
                circle(d=t);
            }
            difference() {
                children();
                minkowski() {
                    shell2d(center_on_border=false,t=t/2) {
                        children();
                    }
                    circle(d=t);
                }
            }
        }
    } else {
        difference() {
            minkowski() {
                children();
                circle(d=t*2);
            }
            children();
        }
    }
}

/**
Picks out the $EPS-thick layer above z=0.
*/
module base() {
  intersection() {
    children();
    linear_extrude(height=$EPS) {
      square($FOREVER,center=true);
    }
  }
}

/**
Round the bottom corners or a print, for avoiding corner-curl-up.
Assumes the are on the XY plane is the bottom, that touches the print bed.
Optimized for rectangular bases, coordinate aligned - but use `angle` for other angles.
Has trouble with separate objects too close together; try 2r apart.  (Not sure whether that can be reasonably fixed.)
Is sortof computationally heavy.
*/
module cornerRound(r=3, angle=0) {
  F = sqrt(2);
  difference() {
    children();
    minkowski() {
      difference() {
        minkowski() {
          base() children();
          linear_extrude(height=$EPS) {
            rz(angle) rz(45) square(r*F,center=true);
          }
        }
        minkowski() {
          base() children();
          linear_extrude(height=$EPS) {
            rz(angle) rz(45) square(r*F-$EPS,center=true);
          }
        }
      }
      rz(angle) tz(r) difference() {
        //pyramid(h=sqrt(2)*r*F-1.5*$EPS,l=sqrt(2)*r*F-1.5*$EPS);
        cube(2*(sqrt(2)*r*F-1.5*$EPS), center=true);
        crotate([0,0,90]) crotate([0,0,180]) rx(45) OZp();
      }
    }
  }
}

/**
Like `base` but at any z, plus frills.
*/
module slice(slice_z=0, drop_z=true, do_hull=true) {
    tz(drop_z ? 0 : slice_z) intersection() {
        if (do_hull) {
            tz(-slice_z) hull() children();
        } else {
            tz(-slice_z) children();
        }
        cube([$FOREVER,$FOREVER,$EPS],center=true);
    }
}

module autochamfer0(z=0, r=3) {
  tz(z) cmirror([0,0,1]) minkowski() {
    linear_extrude(height=$EPS) difference() {
      minkowski() {
        difference() {
          square($FOREVER, center=true);
          projection() slice(slice_z=z, drop_z=false, do_hull=false) children();
        }
        circle(r=$EPS);
      }
      difference() {
        square($FOREVER, center=true);
        projection() slice(slice_z=z, drop_z=false, do_hull=false) children();
      }
    }
    cylinder(d1=r*2, d2=0, h=r);
  }
}

/**
Chamfer at a particular z-height.  (Computationally heavy.)
Turn off `apply` to just get the subtractive chamfer shape, like for if you want to only
chamfer a particular area.
*/
module autochamfer(z=0, r=3, apply=true) {
  if (apply) {
    difference() {
      children();
      autochamfer0(z, r) children();
    }
  } else {
    autochamfer0(z, r) children();
  }
}
 
/**
Cone between two arbitrary circles.
`c` is the [x,y,z] position of the center of the circle.
`a` is the [x,y,z] rotation of the circle.
`d` is the diameter of the circle.
`pad` is added to the height of the extrusion of the circles.  Add e.g. 0.0001 if you're removing the center of an omnicone, or you'll probably get weird thin membranes.
*/
module omnicone(c1, a1, d1, c2, a2, d2, pad=0) {
    hull() {
        translate(c1) rotate(a1) linear_extrude(height=1e-10+pad, center=true) {
            circle(d=d1);
        }
        translate(c2) rotate(a2) linear_extrude(height=1e-10+pad, center=true) {
            circle(d=d2);
        }
    }
}

module ctranslate(v) {
  if (is_list(v[0])) {
      for (i = v) {
          translate(i) {
            children();
          }
      }
  } else {
      children();
      translate(v) {
        children();
      }
  }
}

/**
`center` is the point around which the transformation is made.
*/

//RAINY Permit lists for the other ctransforms, and incorporate center somehow maybe

module cmirror(v, center=undef) {
  if (center == undef) {
      children();
      mirror(v) {
        children();
      }
  } else {
    children();
    translate(center) mirror(v) translate(-center) {
      children();
    }
  }
}

module crotate(v, center=undef) {
  if (center == undef) {
      children();
      rotate(v) {
        children();
      }
  } else {
    children();
    translate(center) rotate(v) translate(-center) {
      children();
    }
  }
}

module cscale(v, center=undef) {
  if (center == undef) {
    children();
    scale(v) {
      children();
    }
  } else {
    children();
    translate(center) scale(v) translate(-center) {
      children();
    }
  }
}

module around(p=[0,0,0],r=[0,0,0]) {
    translate(p) rotate(r) translate(-p) {
        children();
    }
}

module caround(p=[0,0,0],r=[0,0,0]) {
    children();
    around(p, r) {
        children();
    }
}

module phull() {
    hull() {
        children();
        linear_extrude(height=$EPS) projection() {
            children();
        }
    }
}

/**
Rotate a vector.

Example; the cubes end up at the same position:

a1 = rands(-180,180,3);
d1 = rands(-10,10,3);
a2 = rands(-180,180,3);
d2 = rands(-10,10,3);
a3 = rands(-180,180,3);
d3 = rands(-10,10,3);

union() {
    translate(ftranslate(d3, frotate(a3, ftranslate(d2, frotate(a2, ftranslate(d1, frotate(a1, [0,0,0]))))))) cube(center=true);
    translate(d3) rotate(a3) translate(d2) rotate(a2) translate(d1) rotate(a1) cube(center=true);
}

*/
function frotate(a, v) = [[cos(a[2])*cos(a[1]), cos(a[2])*sin(a[1])*sin(a[0])-sin(a[2])*cos(a[0]), cos(a[2])*sin(a[1])*cos(a[0])+sin(a[2])*sin(a[0])],
         [sin(a[2])*cos(a[1]), sin(a[2])*sin(a[1])*sin(a[0])+cos(a[2])*cos(a[0]), sin(a[2])*sin(a[1])*cos(a[0])-cos(a[2])*sin(a[0])],
         [-sin(a[1]), cos(a[1])*sin(a[0]), cos(a[1])*cos(a[0])]]*v;

function ftranslate(d, v) = v+d;

//// Shorthands
module tx(dx) {
  translate([dx,0,0]) {
    children();
  }
}

module ty(dy) {
  translate([0,dy,0]) {
    children();
  }
}

module tz(dz) {
  translate([0,0,dz]) {
    children();
  }
}

/**
`center` is the point around which the rotation is made.
*/

module rx(dx, center=undef) {
  if (center == undef) {
    rotate([dx,0,0]) {
      children();
    }
  } else {
    translate(center) rotate([dx,0,0]) translate(-center) {
      children();
    }
  }
}

module ry(dy, center=undef) {
  if (center == undef) {
    rotate([0,dy,0]) {
      children();
    }
  } else {
    translate(center) rotate([0,dy,0]) translate(-center) {
      children();
    }
  }
}

module rz(dz, center=undef) {
  if (center == undef) {
    rotate([0,0,dz]) {
      children();
    }
  } else {
    translate(center) rotate([0,0,dz]) translate(-center) {
      children();
    }
  }
}

module mx(center=undef) {
  if (center == undef) {
    mirror([1,0,0]) {
      children();
    }
  } else {
    translate(center) mirror([1,0,0]) translate(-center) {
      children();
    }
  }
}

module my(center=undef) {
  if (center == undef) {
    mirror([0,1,0]) {
      children();
    }
  } else {
    translate(center) mirror([0,1,0]) translate(-center) {
      children();
    }
  }
}

module mz(center=undef) {
  if (center == undef) {
    mirror([0,0,1]) {
      children();
    }
  } else {
    translate(center) mirror([0,0,1]) translate(-center) {
      children();
    }
  }
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


//// Quadrants
// Useful for cutting away sections of the...everything, but in 2d

// Pick a dir, then use -1 or 1 ; e.g. [1,0,0], [0,0,-1], etc.
module halfPlane(dir=[0,0]) {
    translate(dir*($FOREVER/2)) square($FOREVER,center=true);
}

module QXm(delta=[0,0]) {translate(delta) halfPlane([-1,0]);}
module QXp(delta=[0,0]) {translate(delta) halfPlane([+1,0]);}
module QYm(delta=[0,0]) {translate(delta) halfPlane([0,-1]);}
module QYp(delta=[0,0]) {translate(delta) halfPlane([0,+1]);}

module QXmYm(delta=[0,0]) {translate(delta) halfPlane([-1,-1]);}
module QXmYp(delta=[0,0]) {translate(delta) halfPlane([-1,+1]);}
module QXpYm(delta=[0,0]) {translate(delta) halfPlane([+1,-1]);}
module QXpYp(delta=[0,0]) {translate(delta) halfPlane([+1,+1]);}


//// Overhang tools

module undercut(size=[1,1,1], center=false) {
  translate([center ? -size[0]/2 : 0, center ? -size[1]/2 : 0, center ? -size[2]/2 : 0]) {
    cube(size);
    translate([0,0,size[2]])
    scale([size[0],size[1],size[0]])
    difference() {
      cube(1);
      rotate([0,-45,0])
        cube(3);
    }
  }
}

module ledge(w, h) {
  translate([-w/2,0,-h])
    difference() {
      cube([w,h,h]);
      rotate([45,0,0]) OZm();
    }
}
//ledge(20,10);

module vslot(size) {
  cube([size[0],size[1],size[2]],center=true);
  for (i = [0,1]) mirror([0,0,i])
    translate([0,0,size[2]/2]) rotate([0,45,0]) cube([sqrt(1/2)*size[0],size[1],sqrt(1/2)*size[0]],center=true);
}

module house(size, center=true) {
  cube([size[0],size[1],size[2]],center=center);
  difference() {
    translate([0,0,center ? size[2]/2 : size[2]]) rotate([0,45,0]) cube([sqrt(1/2)*size[0],size[1],sqrt(1/2)*size[0]],center=center);
    OZm();
  }
}
//house([10,10,10]);

module boltAccess(d=10, h=20, angle=90) {
  difference() {
    union() {
      SZ = $FOREVER/2;
      cylinder(d=d, h=h);
      tz(h) sphere(d=d);
      difference() {
        tx(-(d/2)/sin(angle/2)) {
          tz(h) ry(90) omnicone([0,0,0], [0,0,0], 0.001, [0,0,SZ], [0,0,0], 2*SZ);
          rz(-45) cube([SZ*sqrt(2),SZ*sqrt(2),h]);
        }

        // Outer edge
        tx(-(d/2)/sin(angle/2)) OXp([SZ,0,0]);
        
        // Floor
        tx(-(d/2)*cos(90-angle/2)) OXm();        
      }
    }
    OZm();
  }
}

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
        translate([0,-depth*PIN_DEPTH_FACTOR/2 + depth/2,height/3+(height/3-(PIN_HEIGHT_FACTOR*height/3))])
            pinJoinerPin(depth,width*3,height,pin_height_slop=-pin_height_slop,handle=false);
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
    translate([width,-depth*PIN_DEPTH_FACTOR/2 + depth/2,height/3+(height/3-(PIN_HEIGHT_FACTOR*height/3))])
        pinJoinerPin(depth,pinLengthXP,height,pin_height_slop=-pin_height_slop,wedgeAngle=wedgeAngle,handle=false);
    translate([0,-depth*PIN_DEPTH_FACTOR/2 + depth/2,height/3+(height/3-(PIN_HEIGHT_FACTOR*height/3))])
        mirror([1,0,0])
            pinJoinerPin(depth,pinLengthXM,height,pin_height_slop=-pin_height_slop,wedgeAngle=wedgeAngle,handle=false);
}

// Note that the depth and height are that of the joiner, not of the pin itself.
// ...I'm kinda questioning that decision, as it makes it hard for a user to figure out the dims.
module pinJoinerPin(depth=5,width=15,height=15,wedgeAngle=60,pin_height_slop=DEF_PHSLOP,handle=true) {
    translate([0,0,pin_height_slop/4]) {
        d0 = depth*PIN_DEPTH_FACTOR;
        h0 = (height*PIN_HEIGHT_FACTOR/3)-pin_height_slop/2;
        difference() {
            cube([width,d0,h0]);
            translate([-1,0,h0-d0]) rotate([45,0,0]) cube($FOREVER);
            translate([width,d0,-1]) rotate([0,0,-90-wedgeAngle]) cube($FOREVER);
        }
        if (handle) {
            translate([0,-h0+d0,0]) cube([d0,h0,h0]);
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
    translate([-5,3,0]) rotate([-90,0,0]) translate([0,-5*PIN_DEPTH_FACTOR,-DEF_PHSLOP/4]) pinJoinerPin();
}


//// Bearing slot

/**
Slot to hold a bearing.  The result should be removed from a solid surface.
`size` is an array[3].
`nub_diam` is the diameter of the nub.
`nub_scale` is how flat to make the bump, basically.  (It starts off a half-sphere.)
`nub_stem` is how much of a cylinder to insert between the wall and the nub.
`nub_slope_angle` is the angle of the slope cut into the nub.  It's on the -size[1] face.  0 is perpendicular to the wall, and optimized out.
`nub_slope_translation` is how far from the base of the nub the slope is translated.
The nub is on the face perpendicular to the first dimension of `size`.
`dummy` is whether to use a simple dummy shape instead, for faster rendering.
`access_depth`, if specified, is how much of a dummy tunnel to add for inserting the bearing.

Here's an example that worked pretty well with 686 bearings:
difference() {
  cube([B_WIDTH*3,B_BORE*1.1,B_DIAM*3],center=true);
  bearingSlot([SLOT_WIDTH,B_DIAM*1.1,B_DIAM*1.5], nub_diam=B_BORE*1.1, nub_stem=SLOT_FREE/2, nub_slope_angle=60, nub_slope_translation=-SLOT_FREE/2);
}
*/
module bearingSlot(size, nub_diam, nub_scale=0.1, nub_stem=undef, nub_slope_angle=60, nub_slope_translation=0, access_depth=undef, dummy=false) {
  if (dummy) {
    for (i = [0,1]) mirror([0,0,i])
      translate([0,0,size[2]/2]) rotate([0,45,0]) cube([sqrt(1/2)*size[0],size[1],sqrt(1/2)*size[0]],center=true);
    cube(size, center=true);
    if (access_depth != undef) {
      translate([0,-size[1]/2-access_depth/2+0.0001,0]) {
        for (i = [0,1]) mirror([0,0,i])
          translate([0,0,size[2]/2]) rotate([0,45,0]) cube([sqrt(1/2)*size[0],access_depth,sqrt(1/2)*size[0]],center=true);
        cube([size[0],access_depth,size[2]], center=true);
      }
    }
  } else {
    if (nub_stem == undef) {
      bearingSlot(size=size, nub_diam=nub_diam, nub_scale=nub_scale, nub_stem=0.0, nub_slope_angle=nub_slope_angle, nub_slope_translation=nub_slope_translation, access_depth=access_depth, dummy=dummy);
    } else {
      for (i = [0,1]) mirror([0,0,i])
        translate([0,0,size[2]/2]) rotate([0,45,0]) cube([sqrt(1/2)*size[0],size[1],sqrt(1/2)*size[0]],center=true);
      difference() {
        cube(size, center=true);
        for (i = [0,1]) mirror([i,0,0]) translate([nub_stem-size[0]/2,0,0]) {
          difference() {
            union() {
              scale([nub_scale,1,1]) sphere(d=nub_diam);
              rotate([0,-90,0]) cylinder(d=nub_diam, h=nub_stem); //TODO Should there be a ledge to rest on, rather than a shaft?
            }
            translate([-nub_stem+nub_slope_translation,-nub_diam/2,0]) rotate([0,0,nub_slope_angle]) OYm();
          }
        }
        //OZp(); // For inspection
      }
      if (access_depth != undef) {
        translate([0,-size[1]/2-access_depth/2+0.0001,0]) {
          for (i = [0,1]) mirror([0,0,i])
            translate([0,0,size[2]/2]) rotate([0,45,0]) cube([sqrt(1/2)*size[0],access_depth,sqrt(1/2)*size[0]],center=true);
          cube([size[0],access_depth,size[2]], center=true);
        }
      }
    }
  }
}

/**
Tool for placing a bearing in a bearingSlot.  See bearingSlot, and bearingPlacerStick.
Has some slop built in.
*/
module bearingPlacer(size, bearing_diam) {
  difference() {
    translate([0,-(bearing_diam*1.5)/2+bearing_diam,0]) union() {
      cube([size[0]*0.9,bearing_diam*1.5,size[2]*0.95],center=true);
      for (i = [0,1]) mirror([0,0,i])
        translate([0,0,(size[2]*0.95)/2]) rotate([0,45,0]) cube([sqrt(1/2)*size[0]*0.9,bearing_diam*1.5,sqrt(1/2)*size[0]*0.9],center=true);
    }
    translate([0,bearing_diam/2,0]) cube([$FOREVER,bearing_diam,bearing_diam],center=true);
  }
}

module bearingPlacerStick(size, bearing_diam, outer=true) {
  SY = size[1];
  if (!outer) {
      cube([size[0]*0.9,SY,bearing_diam],center=true);
  } else {
    difference() {
      translate([0,-(SY)/2+bearing_diam,0]) union() {
        cube([size[0]*0.9,SY,size[2]*0.95],center=true);
        translate([0,0,(size[2]*0.95)/2]) rotate([0,45,0]) cube([sqrt(1/2)*size[0]*0.9,SY,sqrt(1/2)*size[0]*0.9],center=true);
      }
      cube([$FOREVER,$FOREVER,bearing_diam],center=true);
      OZm();
    }
  }
}
//bearingPlacerStick([10,40,20],10,false);

/*From https://gist.github.com/boredzo/fde487c724a40a26fa9c
 *
 *skew takes an array of six angles:
 *y along x
 *z along x
 *x along y
 *z along y
 *x along z
 *y along z
 */
module skew(dims) {
  matrix = [
    [ 1, tan(dims[0]), tan(dims[1]), 0 ],
    [ tan(dims[2]), 1, tan(dims[3]), 0 ],
    [ tan(dims[4]), tan(dims[5]), 1, 0 ],
    [ 0, 0, 0, 1 ]
  ];
  multmatrix(matrix)
    children();
}

/**
Makes a triangle.
Defaults to right triangle.
Centered on the midpoint of the base.
Rotated to point at `dir`.
*/
module triangle(height=10,width=undef,dir=[0,1]) {
  if (width == undef) {
    triangle(height=height,width=height*2,dir=dir);
  } else {
    from = [0,0];
    rotate([0,0,atan2(dir[1]-from[1],dir[0]-from[0])-90]) scale([width/(height*2),1]) difference() {
      rotate(45) square(height*sqrt(2),center=true);
      translate([0,-height*sqrt(2)]) square(height*sqrt(2)*2,center=true);
    }
  }
}

/**
I didn't do the math on this; I just adjusted numbers until it lined up really close.
Also, it's a sorta lopsided three top-face thing that I no longer remember what I needed it for.
Something else provides a more normal "pyramid" module.
*/
module halfPyramid(height=20) {
  //translate([0,0,-height])
  scale(height*1.7305) {
    //translate([-0.816,0,0])
    //translate([0,0,-0.57])
    difference() {
      translate([-0.0006,0,-0.28817]) rotate([45,35.3,0]) cube(1,center=true);
      OXm();
      OZm();
    }
  }
}

// A few things from CSG.scad

module cubeAt(v, width) {
  translate(v) {
    cube(width, center = true);
  }
}

// Find the unitary vector with direction v. Fails if v=[0,0,0].
function unit(v) = norm(v)>0 ? v/norm(v) : undef; 
// Find the transpose of a rectangular matrix
function transpose(m) = // m is any rectangular matrix of objects
  [ for(j=[0:len(m[0])-1]) [ for(i=[0:len(m)-1]) m[i][j] ] ];
// The identity matrix with dimension n
function identity(n) = [for(i=[0:n-1]) [for(j=[0:n-1]) i==j ? 1 : 0] ];

// computes the rotation with minimum angle that brings a to b
// the code fails if a and b are opposed to each other
function rotate_from_to(a,b) = 
    let( axis = unit(cross(a,b)) )
    axis*axis >= 0.99 ? 
        transpose([unit(b), axis, cross(axis, unit(b))]) * 
            [unit(a), axis, cross(axis, unit(a))] : 
        identity(3);

// An application of the minimum rotation
// Given to points p0 and p1, draw a thin cylinder with its
// bases at p0 and p1
module line(p0, p1, d=1) {
    v = p1-p0;
    translate(p0)
        // rotate the cylinder so its z axis is brought to direction v
        multmatrix(rotate_from_to([0,0,1],v))
            cylinder(d=d, h=norm(v));
}
module line2(p0, p1, d=1) {
    v = p1-p0;
    rotate(45) {
      cylinder(d=d, h=norm(v), $fn=4);
    }
}

// For BOSL joiners
function joiner_depth(w=10, h=20, a=30) = (h/2 - w/3)*tan(a);


module peg(d, h, taper_d=undef, taper_l=5, double_taper=false) {
  if (taper_d == undef) {
    peg(d=d,h=h,taper_d=d*0.75,taper_l=taper_l,double_taper=double_taper);
  } else {
    if (double_taper) {
      cmirror([0,0,1]) translate([0,0,(h-taper_l*2)/2]) cylinder(h=taper_l,d1=d,d2=taper_d);
    } else {
      translate([0,0,(h-taper_l*2)/2]) cylinder(h=taper_l,d1=d,d2=taper_d);
      mirror([0,0,1]) translate([0,0,(h-taper_l*2)/2]) cylinder(h=taper_l,d=d);
    }
    cylinder(h=h-taper_l*2,d=d,center=true);
  }
}

module nailTab(hole=1.5,head=11,back=1,supportF=1.5,t=3,stickout=0) {
    LW = head*supportF;
    translate([-LW/2,0,0]) difference() {
        union() {
            cylinder(d=LW,h=t);
            ty(-LW/2) cube([LW/2+stickout,LW,t]);
        }
        tz(back) cylinder(d=head,h=t);
        cylinder(d=hole,h=t);
    }
}

// Internal, really.  Teardrop.
module ztd(d=10,t=5) {
    rx(90) {
        cylinder(d=d,h=t,center=true);
        rz(45) tz(-t/2) cube([d/2,d/2,t]);
    }
}

/*
Stick this on a surface, then put screws in it to lever the wedge outwards and e.g. jam something into something else.

E.g.
screwWedge(hole_count=2,ignore_overhang=false);
tz(50) screwWedge(,hole_count=2,ignore_overhang=true);
*/
module screwWedge(arm_l=30,arm_h=50,arm_t=2,wedge_angle=30,wedge_gap=0.5,sw_width=10,shoulder_l=10,hole_d=5,hole_count=1,ignore_overhang=false) {
    ty(shoulder_l) {
        SECOND_OVERHANG_SZ = ignore_overhang ? 0 : arm_l;
        if (!ignore_overhang) {
            tz(-SECOND_OVERHANG_SZ) {
                rz(-90) tx(shoulder_l/2) ledge(shoulder_l,sw_width);
                my() cube([sw_width,shoulder_l,SECOND_OVERHANG_SZ]);
            }
        }
        difference() {
            my() cube([sw_width,shoulder_l,arm_h]);
            for (i = [1:hole_count]) {
                translate([hole_d/2+(sw_width-arm_t-hole_d)*0.2,0,(i-0.5)*(arm_h/hole_count)]) ztd(d=hole_d,t=$FOREVER);
            }
        }
        difference() {
            union() {
                tx(sw_width) mx() tz(-SECOND_OVERHANG_SZ) cube([arm_t,arm_l,arm_h+SECOND_OVERHANG_SZ]);
                difference() {
                    tz(-SECOND_OVERHANG_SZ) cube([sw_width,arm_l,arm_h+SECOND_OVERHANG_SZ]);
                    tx(wedge_gap) ty(arm_l) rz(wedge_angle) OXm();
                }
            }
            if (!ignore_overhang) {
                tz(-SECOND_OVERHANG_SZ) rx(45) OZm();
            }
        }
    }
}

/**
U-shape, to cut out a slot for cable ties.
Centered on origin, flat on z+.
*/
module cableTie(t=4,d=10,h=$FOREVER) {
  translate([-t/2,-(d+t)/2,0]) {
    ctranslate([0,d,0]) cube([t,t,h]);
    cube([t,d+t,t]);
  }
}

/**
Makes an open-top box shape.  Note: if `center`, centers as though
there were a top wall of `thickness` present, i.e., it centers the
inside of the box.
*/
module box(dims=[10,10,10], thickness=1, center=false) {
    difference() {
        if (center) {
            tz(-thickness/2) {
                difference() {
                    cube(dims+[thickness*2,thickness*2,thickness],center=true);
                    tz(thickness/2) cube(dims,center=true);
                }
            }
        } else {
            difference() {
                cube(dims+[thickness*2,thickness*2,thickness],center=false);
                translate(thickness*[1,1,1]) cube(dims,center=false);
            }
        }
    }
}

// US Quarter, for scale reference
module usQuarter() {
  cylinder(d=24.26, h=1.75);
}

module beltBuckle(W=50,GAP=3.5,SX=4,SZ=4,N=3) {
  for (i=[0:N-1]) {
    translate([i,0,0]*(SX+GAP)) cube([SX,W+2*SX,SZ]);
  }
  ctranslate([0,W+SX,0]) cube([N*SX+(N-1)*GAP,SX,SZ]);
}

// Compression slot for a dowel along the y axis; subtract out of a Z+ surface (leaving a concave hollow)
module dowelSlot(D=9.4) {
  tz(D*0.5) rx(90) rz(30) cylinder(d=D/cos(60), h=$FOREVER, $fn=3, center=true);
}

//// Math

/**
`d` diameter of arc
`l` length of arc
returns angle of arc
...This is weird how simple it is
*/
function arcAngle(d,l) = (l/(d/2))*(360/(2*PI));

