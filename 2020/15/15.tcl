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

set turn 1
foreach data [split $indata ","] {
    set num_turn($data) $turn
    set last_num $data
    incr turn
}

# Unset last number since it has be evaluated first
unset num_turn($last_num)

set part1 2020
set part2 30000000

while 1 {
    # Check if the last_num has been seen before
    if {![info exist num_turn($last_num)]} {
        # It hasn't so new number is zero
        set new_num 0
    } else {
        # It has the new number is the age.
        # Age is the last turn minus the stored turn
        set new_num [expr ($turn - 1) - $num_turn($last_num)]
    }

    # Now when the last number has been evaluted store the
    # turn number (which was the last turn)
    set num_turn($last_num) [expr $turn - 1]

    # Print the answers
    if {$turn == $part1} {
        puts "Turn $part1: $new_num"
    }
    if {$turn == $part2} {
        puts "Turn $part2: $new_num"
        exit
    }

    set last_num $new_num
    incr turn
}
