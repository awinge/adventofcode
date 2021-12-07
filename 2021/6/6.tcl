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

set fish [split $indata ","]

# Basic fish simulator, does that the specs say
proc simulate {fish} {

    # A list of new fish spawns
    set new [list]

    # Go through all fish
    for {set i 0} {$i < [llength $fish]} {incr i} {
        set f [lindex $fish $i]

        # Check if it is spawning a new, otherwise just decrement
        if {$f == 0} {
            lset fish $i 6
            lappend new 8
        } else {
            lset fish $i [expr $f - 1]
        }
    }

    # Return the joint list of old and new fish
    return [list {*}$fish {*}$new]
}

# Recursive proc for counting fish with memoization
proc count_fish {fish days} {
    global memo

    # Answer found in memoization
    if {[info exist memo($fish,$days)]} {
        return $memo($fish,$days)
    }

    # Basic case when there is no more days
    if {$days == 0} {
        set memo($fish,$days) [llength $fish]
        return $memo($fish,$days)
    }

    # Basic case when there is only one fish
    # This is the only time we simulate fish
    if {[llength $fish] == 1} {
        set memo($fish,$days) [count_fish [simulate $fish] [expr $days - 1]]
        return $memo($fish,$days)
    }

    # Otherwise divide the fish into two equally sized lists and run recursivly
    set divide [expr [llength $fish] / 2]
    set first [lrange $fish 0 [expr $divide -1]]
    set second [lrange $fish $divide end]

    set memo($fish,$days) [expr [count_fish $first $days] + [count_fish $second $days]]
    return $memo($fish,$days)
}

puts "Fish after 80 days:  [count_fish $fish 80]"
puts "Fish after 256 days: [count_fish $fish 256]"
