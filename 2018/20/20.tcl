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

# Process to set a room as visited with the number of steps
# Returns 0 if a shorter path was found or the room was not
# checked before.
# Otherwise return 1
proc check_room {x y steps} {
    global map

    if {![info exists map($x,$y)] || $steps < $map($x,$y)} {
        set map($x,$y) $steps
        return 0
    }
    return 1
}

# Process to check all rooms
proc create_map {reg x y steps} {
    set depth 0
    set part [list]

    # Start checking character per character
    for {set i 0} {$i < [string length $reg]} {incr i} {
        set c [string index $reg $i]
        switch $c {
            N {
                # If the depth is zero. Move and check the room
                # Otherwise save to check recursive
                if {$depth == 0} {
                    incr y -1
                    incr steps
                    # If the room was visited before with more steps
                    # Stop searching this path
                    if {[check_room $x $y $steps] == 1} {
                        return
                    }
                } else {
                    lappend part $c
                }
            }
            W {
                if {$depth == 0} {
                    incr x -1
                    incr steps
                    if {[check_room $x $y $steps] == 1} { return }
                } else {
                    lappend part $c
                }
            }
            E {
                if {$depth == 0} {
                    incr x +1
                    incr steps
                    if {[check_room $x $y $steps] == 1} { return }
                } else {
                    lappend part $c
                }
            }
            S {
                if {$depth == 0} {
                    incr y +1
                    incr steps
                    if {[check_room $x $y $steps] == 1} { return }
                } else {
                    lappend part $c
                }
            }
            \( {
                if {$depth != 0} {
                    lappend part $c
                }
                incr depth
            }
            \) {
                incr depth -1
                # If depth is back at zero, call create_map recursive
                # Once on each part found
                if {$depth == 0} {
                    lappend parts [join $part ""]
                    set rest [string range $reg [expr $i + 1] end]
                    foreach part $parts {
                        create_map "${part}${rest}" $x $y $steps
                    }
                    return
                } else {
                    lappend part $c
                }
            }
            | {
                # If we are on the first depth level, append the chars collected
                # as a part in parts (used for recursive calls above)
                if {$depth == 1} {
                    lappend parts [join $part ""]
                    set part [list]
                } else {
                    lappend part $c
                }
            }
        }
    }
}

create_map $indata 0 0 0

# Get the maximum room distance within the map
foreach {key steps} [array get map] {
    if {![info exists max_steps] || $steps > $max_steps} {
        set max_steps $steps
    }
}

puts "Largest number of doors: $max_steps"


# Get the number of rooms that is reached by going through
# at least 1000 doors
foreach {key steps} [array get map] {
    if {$steps >= 1000} {
        incr counter
    }
}

puts "Rooms reached with >=1000 doors: $counter"
