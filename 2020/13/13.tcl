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

set earliest [lindex $indata 0]

foreach data [split [lindex $indata 1] ","] {
    if {$data != "x"} {
        if {[regexp {([0-9]*)} $data match bus]} {
            lappend busses $bus
        }
    }
}

# Get the number of minues to wait for each bus
# Make a list with minutes and bus id
foreach bus $busses {
    lappend departures [list [expr $bus - ($earliest % $bus)] $bus]
}

# Sort the list by the least amount of minues
set departures [lsort -integer -index 0 $departures]

# Get the minutes and bus
lassign [lindex $departures 0] dep bus
puts "bus ($bus) * minutes ($dep): [expr $dep * $bus]"


# Get the indexes for the busses
foreach data [split [lindex $indata 1] ","] {
    lappend all $data
}
set indexes [lsearch -all -not $all x]

# Create a list of bus id and indexes
set busindex [lmap a $busses b $indexes {list $a $b}]


# Proc to check if time t fullfilles requirement for bus ID with corresponding index
proc check {t bus index} {
    # time % bus = (bus - index)

    if {[expr ($t % $bus)] == [expr ($bus - $index) % $bus]} {
        return 1
    } else {
        return 0
    }
}

# Proc to find a time starting from start that fullfills requirements,
# time increment is inc
proc find_next {start inc bus index} {
    set num $start

    while {[check $num $bus $index] == 0} {
        incr num $inc
    }

    return $num
}

# Go through all busses multiplying increment with the bus ID after
# each step. This is possible since all bus IDs are prime.
set t 0
set inc 1
foreach bi $busindex {
    lassign $bi b i

    set t [find_next $t $inc $b $i]
    set inc [expr $inc * $b]
}

puts "Earliest timestamp: $t"
