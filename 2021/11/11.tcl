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

# Parsing indata and put it in an array called grid
set y 0
foreach data $indata {
    set x 0

    foreach p [split $data ""] {
        set grid($x,$y) $p
        incr x
    }
    set x 0
    incr y
}

# Proc for incrementing all entries in the grid
proc incr_all {gridname} {
    upvar 1 $gridname grid

    set x 0
    set y 0

    while {[info exists grid(0,$y)]} {
        while {[info exists grid($x,0)]} {
            incr grid($x,$y)
            incr x
        }
        set x 0
        incr y
    }
}

# Proc for printing the grid (used for debug)
proc print {gridname} {
    upvar 1 $gridname grid

    set x 0
    set y 0

    while {[info exists grid(0,$y)]} {
        while {[info exists grid($x,0)]} {
            puts -nonewline "$grid($x,$y) "
            incr x
        }
        puts ""
        set x 0
        incr y
    }
}

# Proc for flashing
# I.e. increasing all adjasent squares
proc flash {gridname x y} {
    upvar 1 $gridname grid

    # Deltas for all adjacent
    set dxs {-1 0 1 -1 1 -1 0 1}
    set dys {-1 -1 -1 0 0 1 1 1}

    # Go through allt he deltas and increase
    for {set i 0} {$i < [llength $dxs]} {incr i} {
        set dx [lindex $dxs $i]
        set dy [lindex $dys $i]

        if {[info exists grid([expr $x + $dx],[expr $y + $dy])]} {
            incr grid([expr $x + $dx],[expr $y + $dy])
        }
    }
}

# Proc for handling a step
# It counts the number of flashes in "flashes" and
# will set all_flash when all flash at the same time
proc step {gridname} {
    upvar 1 flashes flashes
    upvar 1 $gridname grid
    upvar 1 all_flash all_flash

    incr_all grid

    set new_flash 1

    # As long as there are new flashes, continue to go through the grid
    while {$new_flash} {
        set new_flash 0
        set x 0
        set y 0
        while {[info exists grid(0,$y)]} {
            while {[info exists grid($x,0)]} {

                # If it has not flashed before and the value is greater than 9, flash
                if {![info exists flash($x,$y)] && $grid($x,$y) > 9} {
                    set new_flash 1
                    set flash($x,$y) 1
                    incr flashes

                    flash grid $x $y
                }
                incr x
            }
            set x 0
            incr y
        }
    }

    # No more flashes. Now go through and set all grid
    # entires that flashed to zero
    if {[info exists flash]} {
        if {[array size flash] == [array size grid]} {
            set all_flash 1
        }

        foreach {k v} [array get flash] {
            set grid($k) 0
        }
        array unset flash
    }
}

set i 0
set p1 0
set p2 0

while {$p1 != 1 || $p2 != 1} {
    incr i
    step grid

    if {$i == 100} {
        set p1 1
        puts "Flashes after 100 steps: $flashes"
    }

    if {[info exist all_flash]} {
        set p2 1
        puts "All flashed on step: $i"
    }
}
