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


# Proc for explode
# Returns a list with
#   First element set to 1 if a change occured otherwise 0
#   Second element is the exploded number or original number
proc explode {a} {
    set depth 0

    set change 0
    for {set i 0} {$i < [string length $a]} {incr i} {

        # Check if the next part of the string is a number
        # Keep track of the position and value
        if {[regexp {(^[0-9]+)} [string range $a $i end] match left_value]} {
            set left $i

            # Skip the complete number
            incr i [expr [string length $left_value] - 1]
            continue
        }

        # Keep track of the depth
        switch [string index $a $i] {
            "\[" {
                incr depth
            }
            "\]" {
                incr depth -1
            }
        }

        # Time to explode
        if {$depth == 5} {
            # Guaranteed to be a single number here get the parts as f and s
            regexp {\[([0-9]+),([0-9]+)\]} [string range $a $i end] match f s

            # Replace the exploding number with zero
            set pair_length [string length $match]
            set a [string replace $a $i [expr $i + $pair_length - 1] 0]

            # Search for the next number if any
            for {set j [expr $i + 1]} {$j < [string length $a]} {incr j} {
                if {[regexp {(^[0-9]+)} [string range $a $j end] match right_value]} {
                    set right $j
                    break
                }
            }

            # Replace number to the right if it exists
            if {[info exist right]} {
                set start $right
                set stop [expr $start + [string length $right_value] - 1]
                set new_value [expr $right_value + $s]

                set a [string replace $a $start $stop $new_value]
            }

            # Replace number to the left if it exists
            if {[info exist left]} {
                set start $left
                set stop [expr $left + [string length $left_value] - 1]
                set new_value [expr $left_value + $f]

                set a [string replace $a $start $stop $new_value]
            }

            set change 1
            break
        }
    }
    return [list $change $a]
}

# Proc for split
# Returns a list with
#   First element set to 1 if a change occured otherwise 0
#   Second element is the split number or original number
proc split {a} {
    set change 0
    if {[regexp {([0-9]{2,})} $a match hit]} {
        set change 1

        set start [string first $hit $a]
        set stop  [expr $start + [string length $hit] - 1]

        set left [expr $hit / 2]
        set right [expr ($hit + 1) / 2]

        set sub "\[$left,$right\]"

        set a [string replace $a $start $stop $sub]
    }
    return [list $change $a]
}

# Proc for calculating the magnitude
proc magnitude {a} {
    # While a pair of numbers is found
    while {[regexp {\[([0-9]+),([0-9]+)\]} $a match f s]} {

        set i [string first $match $a 0]

        # Replace the number (pair) with the calculated magnitude
        set pair_length [string length $match]
        set a [string replace $a $i [expr $i + $pair_length - 1] [expr 3*$f + 2*$s]]
    }

    return $a
}

# Proc for reducing, i.e. exploding first and then splitting
proc reduce {a} {
    set change 1
    while {$change} {
        lassign [explode $a] change a

        if {$change} {
            continue
        }

        lassign [split $a] change a

        if {$change} {
            continue
        }

        break
    }
    return $a
}

# Proc for adding two numbers
proc add {a b} {
    set sum "\[$a,$b\]"

    return [reduce $sum]
}


# Sum all the numbers
foreach data $indata {
    if {![info exist sum]} {
        set sum $data
    } else {
        set sum [add $sum $data]
    }
}

puts "Magnitude of sum: [magnitude $sum]"

# Try to add all numbers together (both i + j and j + i)
# and find the maximum magnitude
for {set i 0} {$i < [llength $indata]} {incr i} {
    for {set j 0} {$j < [llength $indata]} {incr j} {

        if {$i == $j} {
            continue
        }

        # Get the numbers
        set first [lindex $indata $i]
        set second [lindex $indata $j]

        set sum [add $first $second]
        set magnitude [magnitude $sum]

        if {![info exist max] || $magnitude > $max} {
            set max $magnitude
        }
    }
}

puts "Largest magnitude: $max"
