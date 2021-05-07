/**
Automatically create lids for arbitrary shapes!  See examples.
*/

use <misc.scad>

BIG = 1000;
EPS = 1e-3; //TODO Should maybe be smaller - but I had some problems I was too lazy to fix by different means.
//$fn = 100;

module slice(slice_z=0, drop_z=true, do_hull=true) {
    tz(drop_z ? 0 : slice_z) intersection() {
        if (do_hull) {
            tz(-slice_z) hull() children();
        } else {
            tz(-slice_z) children();
        }
        cube([BIG,BIG,EPS],center=true);
    }
}

module lid_inner(slice_z=0, size=2, size_r=undef, size_h=undef) {
    if (size_r == undef) {
        lid_inner(slice_z=slice_z,size=size,size_r=size/2,size_h=size_h) {
            children();
        }
    } else if (size_h == undef) {
        lid_inner(slice_z=slice_z,size=size,size_r=size_r,size_h=size) {
            children();
        }
    } else {
        echo(size_r, size_h);
        tz(slice_z) minkowski() {
            intersection() {
                difference() {
                    minkowski() {
                        slice(slice_z=slice_z) {
                            children();
                        }
                        union() {
                            cylinder(d1=size_r*2,d2=0,h=size_h/2);
                            mirror([0,0,1]) cylinder(d1=size_r*2,d2=0,h=size_h/2);
                        }
                    }
                    minkowski() {
                        slice(slice_z=slice_z) {
                            children();
                        }
                        cylinder(d=EPS,h=BIG,center=true);
                    }
                }
                minkowski() {
                    slice(slice_z=slice_z,do_hull=false) {
                        children();
                    }
                    cylinder(d=size_r*2,h=BIG,center=true);
                }
            }
            cube(EPS*10);
        }
    }
}

module lid_outer(slice_z=0, size=2, thick=2, size_r=undef, size_h=undef) {
    if (size_r == undef) {
        lid_outer(slice_z=slice_z,size=size,thick=thick,size_r=size/2,size_h=size_h) {
            children();
        }
    } else if (size_h == undef) {
        lid_outer(slice_z=slice_z,size=size,thick=thick,size_r=size_r,size_h=size) {
            children();
        }
    } else {
        difference() {
            tz(slice_z-size_h/2) difference() {
                minkowski() {
                    slice(slice_z=slice_z) {
                        children();
                    }
                    cylinder(d=thick+size_r*2,h=thick+size_h); //TODO d=thick... ?
                }
                minkowski() {
                    slice(slice_z=slice_z) {
                        children();
                    }
                    cylinder(d=EPS,h=size_h);
                }
            }
            ctranslate([0,0,-size_h/2]) lid_inner(slice_z=slice_z,size=size,size_r=size_r,size_h=size) {
                children();
            }
        }
    }
}

module autolid(lid=undef, top_z=0, size=2, thick=2, size_r=undef, size_h=undef) {
    if (lid == undef) {
        for (i=[false,true]) {
            autolid(lid=i, top_z=top_z, size=size, thick=thick, size_r=size_r, size_h=size_h) {
                children();
            }
        }
    } else if (size_r == undef) {
        autolid(lid=lid, top_z=top_z, size=size, thick=thick, size_r=size/2, size_h=size_h) {
            children();
        }
    } else if (size_h == undef) {
        autolid(lid=lid, top_z=top_z, size=size, thick=thick, size_r=size_r, size_h=size) {
            children();
        }
    } else {
        difference() {
            union() {
                if (lid) {
                    tz(2) lid_outer(slice_z=top_z,size=size) {
                        children();
                    }
                } else {
                    tz(-0.5*size) lid_inner(slice_z=top_z,size=size) {
                        children();
                    }
                    children();
                }
            }
            //OXp();
        }
    }
}

// Examples

*difference() {
    for (i=[true,false]) {
        autolid(lid=i,top_z=10,size=2) {
            cylinder(d=20,h=10);
        }
    }
    OXpYp($FOREVER=BIG);
}

*autolid(lid=true,top_z=40,size=4) {
    difference() {
        cylinder(d=60,h=40);
        tz(5) cylinder(d=50,h=40);
    }
}

*autolid(lid=false,top_z=10) {
    cube([10,3,10]);
    ty(20) cube([10,3,10]);
}

*autolid(lid=false,top_z=10) {
    cylinder(d=5,h=10);
    ty(20) cylinder(d=5,h=10);
}
