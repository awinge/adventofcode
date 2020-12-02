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

proc get_valid {passwords} {
    foreach password $passwords {
        # Parse
        if {[regexp {([0-9]+)-([0-9]+) ([a-z]): ([a-z]*)} $password match min max char password]} {
            set occur [llength [lsearch -all [split $password ""] $char]]
            if {$occur >= $min && $occur <= $max} {
                incr valid
            }
        } else {
            puts "Could not parse: $password"
        }
    }
    return $valid
}

puts "Valid passwords: [get_valid $indata]"

proc get_valid2 {passwords} {
    foreach password $passwords {
        # Parse
        if {[regexp {([0-9]+)-([0-9]+) ([a-z]): ([a-z]*)} $password match first second char password]} {
            # Get string indexes
            set indexes [list [expr $first - 1] [expr $second - 1]]

            set match 0
            foreach index $indexes {
                if {[string index $password $index] == $char} {
                    incr match
                }
            }

            if {$match == 1} {
                incr valid
            }
        } else {
            puts "Could not parse: $password"
        }
    }
    return $valid
}

puts "Valid passwords: [get_valid2 $indata]"
