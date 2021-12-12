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

foreach data $indata {

    lassign [split $data "-"] start end

    lappend map($start) $end
    lappend map($end) $start
}


# Traverse the caves
#
# mapname     - The map name
# visitedlist - A list of visited caves
# twice       - Has any small cave been visited twice
# cave        - current cave that is being processed
# path        - A string of the path taken so far
proc traverse {mapname visitedlist twice cave path} {
    upvar 1 $mapname map
    upvar 1 paths paths

    # Recreate the array from the list
    array set visited $visitedlist

    # Add the current cave to the path
    if {$path == ""} {
        append path "$cave"
    } else {
        append path ",$cave"
    }

    # If this is the end, then add the path to paths and count it
    if {$cave == "end"} {
        lappend paths $path
        return 1
    }

    # If the the current cave it "start" and it has already been visited
    # the path is not allowed, return 0
    if {$cave == "start" && [info exists visited($cave)]} {
        return 0
    }

    # If any small cave has been visited twice and the current cave has already
    # been visited, and it is a small cave. The path is not allowed, return 0
    if {$twice && [info exists visited($cave)] && [string tolower $cave] == $cave} {
        return 0
    }

    # If the current cave has been visited and it is a small cave, allow it
    # but now twice it set. No more double visits allowed
    if {[info exists visited($cave)] && [string tolower $cave] == $cave} {
        set twice 1
    }

    # Tha cave has been visited
    set visited($cave) 1

    # Foreach next cave in the map traverse it and accumulate the result
    foreach next $map($cave) {
        incr ret [traverse map [array get visited] $twice $next $path]
    }

    return $ret
}

puts "Paths visiting small caves at most once: [traverse map {} 1 start ""]"
puts "Paths visiting one small cave at most twice: [traverse map {} 0 start ""]"
