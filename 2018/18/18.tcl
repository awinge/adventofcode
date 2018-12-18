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

# Creating the area
# Saving the maximum x and maximum y
set y 0
foreach data $indata {
    set x 0
    foreach char [split $data ""] {
        set area($x,$y) $char
        incr x
    }
    set maxx [expr $x - 1]
    incr y
}
set maxy [expr $y - 1]

# Print the area, only for debug
proc print {} {
    global area

    set y 0
    while {[info exists area(0,$y)]} {
        set x 0
        while {[info exists area($x,$y)]} {
            puts -nonewline $area($x,$y)
            incr x
        }
        puts ""
        incr y
    }
}

# Counting the open, trees and lumberyards in the adjacent areas
# Returning all three as a list
proc get_adjacent {cx cy} {
    global area
    global maxx maxy

    set open_ground 0
    set trees       0
    set lumberyard  0

    for {set y [expr $cy - 1]} {$y <= [expr $cy + 1]} {incr y} {
        for {set x [expr $cx - 1]} {$x <= [expr $cx + 1]} {incr x} {
            if {$x >= 0 && $x <= $maxx &&
                $y >= 0 && $y <= $maxy &&
                ($x != $cx || $y != $cy)} {

                switch $area($x,$y) {
                    . { incr open_ground }
                    | { incr trees }
                    # { incr lumberyard }
                }
            }
        }
    }
    return [list $open_ground $trees $lumberyard]
}

# Transform the area according to the set rules
proc transform {} {
    global area

    # Building a new_area list of key1 value1 key2 value2
    # which is then used in array set below
    foreach {key value} [array get area] {
        lassign [split $key ,] x y
        lassign [get_adjacent $x $y] o t l

        switch $value {
            . {
                if {$t >= 3} {
                    lappend new_area $x,$y |
                } else {
                    lappend new_area $x,$y .
                }
            }
            | {
                if {$l >= 3} {
                    lappend new_area $x,$y #
                } else {
                    lappend new_area $x,$y |
                }
            }
            \# {
                if {$l >= 1 && $t >= 1} {
                    lappend new_area $x,$y #
                } else {
                    lappend new_area $x,$y .
                }
            }
        }
    }
    array set area $new_area
}

# Count open, trees and lumberyards in the complete area
# Returning all three as a list
proc count {} {
    global area

    set open_ground 0
    set trees       0
    set lumberyard  0

    foreach {key value} [array get area] {
        switch $value {
            . { incr open_ground }
            | { incr trees }
            # { incr lumberyard }
        }
    }
    return [list $open_ground $trees $lumberyard]
}

# Testing revealed periodicness starts after
# around 500 transformations, run 600 to be sure
lappend counts [count]
for {set i 1} {$i <= 600} {incr i} {
    transform
    lappend counts [count]

    # Printout the answer to the first part
    if {$i == 10} {
        lassign [lindex $counts end] o t l
        puts "Resource value after 10 minutes: [expr $t * $l]"
    }
}

# Finding out the periodicness
set period 0
while 1 {
    incr period

    if {[lindex $counts end] == [lindex $counts end-$period]} {
        break
    }
}

# Calculate which offset to use and correspond it to the calculated values
set mod [expr 1000000000 % $period]
set mod_start [expr $period * ((600 / $period) - 1)]

# Get the values
lassign [lindex $counts [expr $mod_start + $mod]] o t l

puts "Resource value after 1000000000 minutes: [expr $t * $l]"
