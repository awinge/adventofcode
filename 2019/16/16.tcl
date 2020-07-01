#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	lappend indata [regexp -inline -all -- {\S+} $row]
    }
}

# Prepare input to a list
set data [split $indata ""]
set init_pattern [list 0 1 0 -1]
set phases 100

puts "Calculating first part..."
for {set phase 1} {$phase <= $phases} {incr phase} {
    # Preparations for a phase run
    set pattern      $init_pattern
    set result_digit []
    
    for {set digit 0} {$digit < [llength $data]} {incr digit} {
        # Preparations for a digit run
        set data_index    0
        set digit_result  0
        set pattern_index 1
        
        # Run as long as there are data elements
        while {$data_index < [llength $data]} {
            switch [lindex $pattern $pattern_index] {
                1 {
                    incr digit_result [lindex $data $data_index]
                }

                -1 {
                    incr digit_result [expr -[lindex $data $data_index]]
                }
            }
            incr data_index
            set pattern_index [expr ($pattern_index + 1) % [llength $pattern]]
        }

        # Update for next digit
        set pattern_length [llength $pattern]
        set pattern [linsert $pattern [expr $pattern_length / 4 * 3] [lindex $init_pattern 3]]
        set pattern [linsert $pattern [expr $pattern_length / 4 * 2] [lindex $init_pattern 2]]
        set pattern [linsert $pattern [expr $pattern_length / 4 * 1] [lindex $init_pattern 1]]
        set pattern [linsert $pattern [expr $pattern_length / 4 * 0] [lindex $init_pattern 0]]
        lappend result_digit [lindex [split $digit_result ""] end]
    }

    # Update values for next phase
    set data $result_digit
}

puts "The first 8 digits [join [lrange $data 0 7] ""]"

# Second step

# Get the data from the input again
set data [split $indata ""]
set data [join [lrepeat 10000 $data]]
set offset [join [lrange $data 0 6] ""]

# Prepare data for the loop (get rid of digits before the offset)
set data [lrange $data $offset end]

# This is a dirty solution assuming that we're always just adding the digits.
# I.e. the pattern is only 1. Otherwise abort mission
if {$offset <= [llength $data]} {
    puts "This quick solution does not work"
    exit
}

puts "Calculating second part..."
set phases 100
for {set phase 1} {$phase <= $phases} {incr phase} {
    set result_digit []
    
    # Sum all up once
    set digit_result [expr [join $data "+"]]
    lappend result_digit [lindex [split $digit_result ""] end]

    for {set digit 1} {$digit < [llength $data]} {incr digit} {
        # Remove the last digit from the sum
        set digit_result [expr $digit_result - [lindex $data [expr $digit - 1]]]
        
        # Get last digit as result
        lappend result_digit [lindex [split $digit_result ""] end]
    }

    # Update values for next phase
    set data $result_digit
}

puts "The 8 digits at the offset: [join [lrange $data 0 7] ""]"
