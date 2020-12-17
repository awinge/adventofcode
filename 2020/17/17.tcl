#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	lappend indata $row
    }
}

# Parse and create grid3 and grid4
set x 0
set y 0
set z 0
set w 0
foreach data $indata {
    set x 0
    foreach pos [split $data ""] {
        if {$pos == "#"} {
            set grid3($x,$y,$z) 1
            set grid4($x,$y,$z,$w) 1
        }

        incr x
    }
    incr y
}

# Initial min and max values
set minx 0
set maxx [expr $x - 1]
set miny 0
set maxy [expr $y - 1]
set minz 0
set maxz 0
set minw 0
set maxw 0

# Get the number of active neighbour cubes in 3D
proc active_3d {x y z} {
    upvar 1 grid3 grid3

    for {set cz -1} {$cz <= 1} {incr cz} {
        for {set cy -1} {$cy <= 1} {incr cy} {
            for {set cx -1} {$cx <= 1} {incr cx} {
                # Skip ourself
                if {$cx == 0 && $cy == 0 && $cz == 0} {
                    continue
                }
                lappend coords "[expr $x + $cx],[expr $y + $cy],[expr $z + $cz]"
            }
        }
    }
    set active 0
    foreach c $coords {
        if {[info exist grid3($c)]} {
            incr active
        }
    }

    return $active
}

# Get the number of active neighbour cubes in 4D
proc active_4d {x y z w} {
    upvar 1 grid4 grid4

    for {set cw -1} {$cw <= 1} {incr cw} {
        for {set cz -1} {$cz <= 1} {incr cz} {
            for {set cy -1} {$cy <= 1} {incr cy} {
                for {set cx -1} {$cx <= 1} {incr cx} {
                    # Skip ourself
                    if {$cx == 0 && $cy == 0 && $cz == 0 && $cw == 0} {
                        continue
                    }
                    lappend coords "[expr $x + $cx],[expr $y + $cy],[expr $z + $cz],[expr $w + $cw]"
                }
            }
        }
    }
    set active 0
    foreach c $coords {
        if {[info exist grid4($c)]} {
            incr active
        }
    }

    return $active
}

# Doing one cycle of both 3D and 4D
proc cycle {} {
    upvar 1 grid3 grid3
    upvar 1 grid4 grid4
    upvar 1 minx minx
    upvar 1 miny miny
    upvar 1 minz minz
    upvar 1 minw minw
    upvar 1 maxx maxx
    upvar 1 maxy maxy
    upvar 1 maxz maxz
    upvar 1 maxw maxw

    # Expand one in each direction per iteration
    incr minx -1
    incr miny -1
    incr minz -1
    incr minw -1
    incr maxx 1
    incr maxy 1
    incr maxz 1
    incr maxw 1

    for {set x $minx} {$x <= $maxx} {incr x} {
        for {set y $miny} {$y <= $maxy} {incr y} {
            for {set z $minz} {$z <= $maxz} {incr z} {
                set active [active_3d $x $y $z]

                if {[info exist grid3($x,$y,$z)]} {
                    if {$active == 2 || $active == 3} {
                        set new_grid3($x,$y,$z) 1
                    }
                } else {
                    if {$active == 3} {
                        set new_grid3($x,$y,$z) 1
                    }
                }

                for {set w $minw} {$w <= $maxw} {incr w} {
                    set active [active_4d $x $y $z $w]

                    if {[info exist grid4($x,$y,$z,$w)]} {
                        if {$active == 2 || $active == 3} {
                            set new_grid4($x,$y,$z,$w) 1
                        }
                    } else {
                        if {$active == 3} {
                            set new_grid4($x,$y,$z,$w) 1
                        }
                    }
                }

            }
        }
    }
    array unset grid3
    array set grid3 [array get new_grid3]
    array unset grid4
    array set grid4 [array get new_grid4]
}

# Do 6 cycles
for {set i 0} {$i < 6} {incr i} {
    puts "cycle: [expr $i + 1]"
    cycle
}

puts "Active cubes 3D: [array size grid3]"
puts "Active cubes 4D: [array size grid4]"
