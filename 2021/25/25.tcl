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


# Parse the input
set y 0
foreach data $indata {
    set x 0
    foreach s [split $data ""] {
        if {$s != "."} {
            set map($x,$y) $s
        }
        incr x
    }
    incr y
}

# Remember the max x and y
set x_size $x
set y_size $y


# Proc for doing a step and return if there was any movement
proc step {mapname} {
    upvar 1 $mapname map
    upvar 1 x_size x_size
    upvar 1 y_size y_size

    # Move to the right first
    set movement 0
    foreach {k v} [array get map] {
        if {$v ==  ">"} {
            lassign [split $k ","] x y

            set new_x [expr ($x + 1) % $x_size]

            if {[info exist map($new_x,$y)]} {
                set new_map($x,$y) ">"
            } else {
                set new_map($new_x,$y) ">"
                set movement 1
            }
        }
        if {$v == "v"} {
            set new_map($k) $v
        }
    }

    array unset map
    array set map [array get new_map]
    array unset new_map

    # Move down
    foreach {k v} [array get map] {
        if {$v ==  "v"} {
            lassign [split $k ","] x y

            set new_y [expr ($y + 1) % $y_size]

            if {[info exist map($x,$new_y)]} {
                set new_map($x,$y) "v"
            } else {
                set new_map($x,$new_y) "v"
                set movement 1
            }
        }

        if {$v == ">"} {
            set new_map($k) $v
        }
    }
    array unset map
    array set map [array get new_map]
    array unset new_map

    return $movement
}


# Proc for printing the map (used for debug)
proc print {mapname} {
    upvar 1 $mapname map
    upvar 1 x_size x_size
    upvar 1 y_size y_size

    for {set y 0} {$y < $y_size} {incr y} {
        for {set x 0} {$x < $x_size} {incr x} {
            if {[info exist map($x,$y)]} {
                puts -nonewline $map($x,$y)
            } else {
                puts -nonewline .
            }
        }
        puts ""
    }
}


# Repeat while there is movements and count the steps
set steps 0
set movement 1
while {$movement} {
    set movement [step map]
    incr steps
}

puts "Step with no movement: $steps"
