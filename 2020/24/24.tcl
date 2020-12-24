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

# Parse the data
foreach data $indata {
    set x 0
    set y 0
    while {$data != ""} {
        if {[regexp {^se(.*)} $data match rest]} {
            incr x +1
            incr y +1
            set data $rest
            continue
        }
        if {[regexp {^sw(.*)} $data match rest]} {
            incr x -1
            incr y +1
            set data $rest
            continue
        }
        if {[regexp {^ne(.*)} $data match rest]} {
            incr x +1
            incr y -1
            set data $rest
            continue
        }
        if {[regexp {^nw(.*)} $data match rest]} {
            incr x -1
            incr y -1
            set data $rest
            continue
        }
        # Stepping east is equal to ne se. I.e. x + 2
        if {[regexp {^e(.*)} $data match rest]} {
            incr x +2
            set data $rest
            continue
        }
        # Stepping west is equal to nw sw. I.e. x - 2
        if {[regexp {^w(.*)} $data match rest]} {
            incr x -2
            set data $rest
            continue
        }

        puts "Unparsed: $data"
    }


    # Only keep track of the black tiles
    if {![info exists tiles($x,$y)]} {
        set tiles($x,$y) 1
    } else {
        unset tiles($x,$y)
    }
}

# Counting the black tiles is the same as the array size
proc count_black {} {
    upvar 1 tiles tiles

    return [array size tiles]
}

# Return the cooridnates of the adjacent tiles to x y
# {x0 y0 x1 y1 ...}
proc adjacent_tiles {x y} {
    upvar 1 tiles tiles

    foreach {dx dy} {-2 0 2 0 -1 -1 -1 1 1 -1 1 1} {
        lappend ret [expr $x + $dx]
        lappend ret [expr $y + $dy]
    }

    return $ret
}

# Count the black tiles adjacent to x y
proc adjacent_black {x y} {
    upvar 1 tiles tiles

    set black 0
    foreach {ax ay} [adjacent_tiles $x $y] {
        if {[info exists tiles($ax,$ay)]} {
            incr black
        }
    }

    return $black
}

# Step the art project one step
proc art {} {
    upvar 1 tiles tiles

    # For every black tile
    foreach {k v} [array get tiles] {
        lassign [split $k ","] x y

        # Check the tile itself and its neighbours
        set check_tiles [list $x $y {*}[adjacent_tiles $x $y]]
        foreach {x y} $check_tiles {

            # Only check the tile if it has not already been checked to speed it up
            if {![info exists checked($x,$y)]} {

                # Get adjacent black tiles and do according to the rules
                set adjblack [adjacent_black $x $y]
                if {[info exists tiles($x,$y)]} {
                    if {$adjblack != 0 && $adjblack <= 2} {
                        set newtiles($x,$y) 1
                    }
                } else {
                    if {$adjblack == 2} {
                        set newtiles($x,$y) 1
                    }
                }
                set checked($x,$y) 1
            }
        }
    }

    array unset tiles
    array set tiles [array get newtiles]
}

puts "Tiles with black side up: [count_black]"

# Do 100 days of the art project
for {set i 0} {$i < 100} {incr i} {
    art
}

puts "Tiles with black side up: [count_black]"
