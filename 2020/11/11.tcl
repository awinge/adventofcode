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

# Parse the input into an array (orig_area)
set y 0
foreach row $indata {
    set x 0
    foreach place [split $row ""] {
        set orig_area($x,$y) $place
        incr x
    }
    incr y
}

set max_x $x
set max_y $y

# Returns number of occupied adjacent seats
# Adjacent is defined as directly next to if sight is set to zero
# Otherwise adjacent is the seats seen in each direction
# The proc operates on the the array "area"
proc adjacent_occupied {x y sight} {
    upvar 1 area area

    lappend checks [list -1 -1]
    lappend checks [list -1 0]
    lappend checks [list -1 1]
    lappend checks [list 0 -1]
    lappend checks [list 0 1]
    lappend checks [list 1 -1]
    lappend checks [list 1 0]
    lappend checks [list 1 1]

    set occupied 0
    foreach check $checks {
        lassign $check cx cy

        set new_x $x
        set new_y $y
        while 1 {
            incr new_x $cx
            incr new_y $cy
            if {[info exists area($new_x,$new_y)]} {
                switch $area($new_x,$new_y) {
                    \# {
                        incr occupied
                        break
                    }
                    . {}
                    L {
                        break
                    }
                }
            } else {
                break
            }
            if {$sight == 0} {
                break
            }
        }
    }

    return $occupied
}

# Prints the area, used for debug
proc print {name max_x max_y} {
    upvar 1 $name area
    for {set y 0} {$y < $max_y} {incr y} {
        for {set x 0} {$x < $max_x} {incr x} {
            puts -nonewline $area($x,$y)
        }
        puts ""
    }
}

# Seating procedure
# limit is the acceptable number of people to be adjacent to
# sight is the adjacent calculation type
proc seating {limit sight} {
    upvar 1 area area

    # Loop this seating rules while people are still moving around
    set changed 1
    while {$changed == 1} {
        set changed 0
        foreach {k v} [array get area] {
            lassign [split $k ","] x y
            set occupied [adjacent_occupied $x $y $sight]

            # Default value
            set new_area($k) $v

            # Check if there shall be changes
            switch $v {
                L {
                    if {$occupied == 0} {
                        set new_area($k) \#
                        set changed 1
                    }
                }
                \# {
                    if {$occupied >= $limit} {
                        set new_area($k) L
                        set changed 1
                    }
                }
            }
        }
        # Done, set the area to be the newly created new_area
        array set area [array get new_area]
    }
}

# Count the number of occupied seats
proc tot_occupied {} {
    upvar 1 area area

    foreach {k v} [array get area] {
        if {$v == "#"} {
            incr num
        }
    }
    return $num
}

array set area [array get orig_area]
seating 4 0
puts "Seats occupied: [tot_occupied]"

array set area [array get orig_area]
seating 5 1
puts "Seats occupied: [tot_occupied]"
