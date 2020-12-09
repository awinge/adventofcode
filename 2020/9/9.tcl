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

# Find two in the list of numbers that adds up to sum
# Returns 1 if numbers are found, 0 otherwise
proc find_two {sum numbers} {
    for {set i 0} {$i < [expr [llength $numbers] - 1]} {incr i} {
        for {set j [expr $i + 1]} {$j < [llength $numbers]} {incr j} {
            set first  [lindex $numbers $i]
            set second [lindex $numbers $j]

            if {[expr $first + $second] == $sum} {
                return 1
            }
        }
    }
    return 0
}

# Skip the first 25 numbers (preamble)
for {set i 25} {$i < [llength $indata]} {incr i} {
    set check [lrange $indata [expr $i - 25] [expr $i - 1]]
    set number [lindex $indata $i]

    if {![find_two $number $check]} {
        break
    }
}

puts "Not sum of two previous(25): $number"

set wanted_sum $number

# Returns the sum of the list of numbers
proc sum {numbers} {
    return [expr [join $numbers +]+0]
}

# Set a range with first and last indexes
# If the sum is too small, increase last index (i.e. sum becomes larger)
# If the sum is too large, increase first index (i.e. sum becomes smaller)
# If the indexes are the same, increase last index (i.e. at least two numbers)
set first 0
set last  1
while 1 {
    set numbers [lrange $indata $first $last]
    set current_sum [sum $numbers]

    if {$current_sum < $wanted_sum} {
        incr last
    }

    if {$current_sum > $wanted_sum} {
        incr first
    }

    if {$current_sum == $wanted_sum} {
        break
    }

    if {$first == $last} {
        incr last
    }

    if {$last >= [llength $indata]} {
        puts "Not found"
        exit
    }
}

# Get the maximum value in the list of numbers
proc max {numbers} {
    set m [lindex $numbers 0]
    foreach n $numbers {
        if {$n > $m} {
            set m $n
        }
    }
    return $m
}

# Get the minimum value in the list of numbers
proc min {numbers} {
    set m [lindex $numbers 0]
    foreach n $numbers {
        if {$n < $m} {
            set m $n
        }
    }
    return $m
}

puts "Encryption weakness: [expr [min $numbers] + [max $numbers]]"
