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

# Parse indata and create a map.
# Map is an array indexed with the location
# Content is a list of next locations and the distance there
foreach data $indata {
    if {[regexp {([a-zA-z]*) to ([a-zA-Z]*) = ([0-9]*)} $data match from to distance]} {
        lappend map($from) [list $to $distance]
        lappend map($to) [list $from $distance]
        continue
    }

    puts "Did not parse: $data"
    exit
}

# Proc for traversing the map finding bot the shortest and longest path
proc traverse {mapname visitedlist location distance} {
    upvar 1 $mapname map
    upvar 1 shortest shortest
    upvar 1 longest longest

    array set visited $visitedlist

    # The place has already been visited. Not allowed. Return
    if {[info exist visited($location)]} {
        return
    }

    set visited($location) 1

    # All locations have been visisted. Check the distance.
    if {[array size map] == [array size visited]} {
        if {![info exists shortest] || $distance < $shortest} {
            set shortest $distance
        }
        if {![info exists longest] || $distance > $longest} {
            set longest $distance
        }
    }

    # Foreach possible next location run recursively
    foreach next $map($location) {
        lassign $next next_location next_distance
        traverse map [array get visited] $next_location [expr $distance + $next_distance]
    }
}


# Traverse the map with all possible start positions
foreach {k v} [array get map] {
    traverse map [] $k 0
}

puts "Shortest route: $shortest"
puts "Longest route: $longest"
