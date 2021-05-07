$FOREVER = 2000;
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

module cmirror(v) {
  children();
  mirror(v) {
    children();
  }
}

module ctranslate(v) {
  children();
  translate(v) {
    children();
  }
}

module crotate(v) {
  children();
  rotate(v) {
    children();
  }
}

module cscale(v) {
  children();
  scale(v) {
    children();
  }
}

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
 *x along y
 *x along z
 *y along x
 *y along z
 *z along x
 *z along y
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