#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	#lappend indata [regexp -inline -all -- {\S+} $row]
	lappend indata $row
    }
}

# Parse the input to a map array
set y 0
set x 0
foreach data $indata {
    set x 0
    foreach d [split $data ""] {
        set map($x,$y) $d
        incr x
    }
    incr y
}

set sizex $x
set sizey $y

# proc for the heuristic function
proc get_h {x0 y0 x1 y1} {
    # Just return zero in this case.
    return 0
}

# proc for getting a list of adjacent positions on the map array
proc get_adjacent {x y} {
    global map

    # Deltas for right, down, left and up
    set dx {1 0 -1 0}
    set dy {0 1 0 -1}

    for {set i 0} {$i < [llength $dx]} {incr i} {
        set new_x [expr $x + [lindex $dx $i]]
        set new_y [expr $y + [lindex $dy $i]]

        if {[info exists map($new_x,$new_y)]} {
            lappend ret $new_x $new_y
        }
    }

    return $ret
}

# Proc implementing A*, do not save the path, only the cost
proc a {sx sy gx gy} {
    global map

    set open_array(0,0) [list 0 0 0]]

    while {[array size open_array] > 0} {

        # Find the node with the lowest f and remove it from the array
        if {[info exist f]} {
            unset f
        }
        foreach {k v} [array get open_array] {
            lassign $v og oh of

            if {![info exist f] || $of < $f} {
                set g $og
                set h $oh
                set f $of
                lassign [split $k ","] x y
            }
        }
        unset open_array($x,$y)

        # Check all adjacent
        foreach {nx ny} [get_adjacent $x $y] {
            # Calculate values for the new node
            set ng [expr $g + $map($nx,$ny)]
            set nh [get_h $nx $ny $gx $gy]
            set nf [expr $ng + $nh]

            # If it is the target node return the distance
            if {$nx == $gx && $ny == $gy} {
                return $ng
            }

            # Check if the node is in the open array
            if {[info exist open_array($nx,$ny)]} {
                lassign $open_array($nx,$ny) og oh of

                if {$nf < $of} {
                    # This is better, replace the node in the open array
                    set open_array($nx,$ny) [list $ng $nh $nf]
                }
                continue
            }

            # Check if the node is in the closed array
            if {[info exist closed_array($nx,$ny)]} {
                if {$nf < $closed_array($nx,$ny)} {
                    # This is better, remove from closed array and add to open array
                    unset closed_array($nx,$ny)
                    set open_array($nx,$ny) [list $ng $nh $nf]
                }
                continue
            }

            # Not found in open or closed, just add it to the open array
            set open_array($nx,$ny) [list $ng $nh $nf]
        }

        # It is now processed, add it to the closed array
        set closed_array($x,$y) $f
    }
}

set gx [expr $sizex - 1]
set gy [expr $sizey - 1]

puts "Total risk: [a 0 0 $gx $gy]"

# Expand the map
foreach {k v} [array get map] {
    lassign [split $k ","] x y

    for {set dx 0} {$dx < 5} {incr dx} {
        for {set dy 0} {$dy < 5} {incr dy} {
            set nv [expr $v + $dx + $dy]
            while {$nv > 9} {
                incr nv -9
            }
            set map([expr $sizex * $dx + $x],[expr $sizey * $dy + $y]) $nv
        }
    }
}
set sizex [expr $sizex * 5]
set sizey [expr $sizey * 5]
set gx [expr $sizex - 1]
set gy [expr $sizey - 1]

puts "Total risk: [a 0 0 $gx $gy]"
