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

# Rotate the ship num rotations in rot direction
# Returns new direction
proc rotate_ship {current rot num} {
    set directions {E S W N}

    set current_index [lsearch $directions $current]
    if {$current_index == -1} {
        puts "Unknown current: $current"
    }

    for {set i 0} {$i < $num} {incr i} {
        switch $rot {
            L {
                set current_index [expr (4 + $current_index - 1) % 4]
            }
            R {
                set current_index [expr ($current_index + 1) % 4]
            }
            default {
                puts "Unknown rot: $rot"
            }
        }
    }
    return [lindex $directions $current_index]
}

# Move x y num steps in direction dir
# Returns new position
proc move {cx cy dir num} {
    switch $dir {
        E {
            incr cx $num
        }
        S {
            incr cy $num
        }
        W {
            incr cx -$num
        }
        N {
            incr cy -$num
        }
        default {
            puts "Unkown dir: $dir"
        }
    }

    return [list $cx $cy]
}

# Execute instruction in part 1
# Returns new coordinate and direction of ship
proc execute {ship_x ship_y ship_dir instruction} {
    if {[regexp {(E|S|W|N)([0-9]*)} $instruction match move_dir num]} {
        lassign [move $ship_x $ship_y $move_dir $num] ship_x ship_y
        return [list $ship_x $ship_y $ship_dir]
    }
    if {[regexp {(L|R)([0-9]*)} $instruction match rot deg]} {
        set num [expr $deg / 90]
        set ship_dir [rotate_ship $ship_dir $rot $num]
        return [list $ship_x $ship_y $ship_dir]
    }
    if {[regexp {F([0-9]*)} $instruction match num]} {
        lassign [move $ship_x $ship_y $ship_dir $num] ship_x ship_y
        return [list $ship_x $ship_y $ship_dir]
    }

    puts "Unknown instruction: $instruction"
}

set ship_dir E
set ship_x 0
set ship_y 0

foreach data $indata {
    lassign [execute $ship_x $ship_y $ship_dir $data] ship_x ship_y ship_dir
}

puts "Manhattan from start: [expr abs($ship_x) + abs($ship_y)]"

# Rotate x y num rotations in rot direction
# Returns new position
proc rotate_way {x y rot num} {
    for {set i 0} {$i < $num} {incr i} {
        switch $rot {
            L {
                set tmpy [expr -$x]
                set tmpx [expr $y]
            }
            R {
                set tmpy [expr $x]
                set tmpx [expr -$y]
            }
            default {
                puts "Unknown rot: $rot"
            }
        }

        set x [expr $tmpx]
        set y [expr $tmpy]
    }
    return [list $x $y]
}

# Execute instruction in part 2
# Returns new cooridnates for ship and waypoint
proc execute2 {ship_x ship_y way_x way_y instruction} {
    if {[regexp {(E|S|W|N)([0-9]*)} $instruction match move_dir num]} {
        lassign [move $way_x $way_y $move_dir $num] way_x way_y
        return [list $ship_x $ship_y $way_x $way_y]
    }
    if {[regexp {(L|R)([0-9]*)} $instruction match rot deg]} {
        set num [expr $deg / 90]
        lassign [rotate_way $way_x $way_y $rot $num] way_x way_y
        return [list $ship_x $ship_y $way_x $way_y]
    }
    if {[regexp {F([0-9]*)} $instruction match num]} {
        incr ship_x [expr $num * $way_x]
        incr ship_y [expr $num * $way_y]
        return [list $ship_x $ship_y $way_x $way_y]
    }

    puts "Unknown instruction: $instruction"
}

set ship_x 0
set ship_y 0
set way_x 10
set way_y -1

foreach data $indata {
    lassign [execute2 $ship_x $ship_y $way_x $way_y $data] ship_x ship_y way_x way_y
}

puts "Manhattan from start: [expr abs($ship_x) + abs($ship_y)]"
