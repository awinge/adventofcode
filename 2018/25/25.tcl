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

# Calculating the manhattan distance in four dimensions
proc manhattan {a b} {
    lassign $a a1 a2 a3 a4
    lassign $b b1 b2 b3 b4

    return [expr abs($a1-$b1) + abs($a2-$b2) + abs($a3-$b3) + abs($a4-$b4)]
}

# Create a list of all the input points
foreach data $indata {
    if {[regexp {([-\d]*),([-\d]*),([-\d]*),([-\d]*)} $data _match a b c d]} {
        lappend points [list $a $b $c $d]
    } else {
        puts "Could not parse $data"
    }
}

set constallation_number 0

for {set i 0} {$i < [llength $points]} {incr i} {
    set current [lindex $points $i]

    for {set j 0} {$j < $i} {incr j} {
        set compare [lindex $points $j]

        # Check if the manhattan distance is within constallation range
        if {[manhattan $current $compare] <= 3} {
            # Merging the current point into the constallation it first is in range of
            # if is is range of more than one constallation, these are merged.
            if {![info exists constallations([join $current ,])]} {
                set constallations([join $current ,]) $constallations([join $compare ,])
                set combining_constallation $constallations([join $compare ,])
            } else {
                # Possible group combining
                set group $constallations([join $compare ,])
                foreach {key value} [array get constallations] {
                    if {$value == $group} {
                        set constallations($key) $combining_constallation
                    }
                }
            }
        }
    }

    # If not in range of any constallation, create a new one
    if {![info exists constallations([join $current ,])]} {
        set constallations([join $current ,]) $constallation_number
        incr constallation_number
    }
}

# Check how many unique constallation numbers that are used
foreach {key value} [array get constallations] {
    lappend constallation_numbers $value

    set constallation_numbers [lsort -unique $constallation_numbers]
}

puts "Constallations: [llength $constallation_numbers]"
