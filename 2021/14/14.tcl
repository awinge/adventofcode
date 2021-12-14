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

# Parse input get the initial polymer and pair insertion data
foreach data $indata {
    if {[regexp {([A-Z]*) -> ([A-Z])} $data match from to]} {
        set insertion($from) $to
        continue
    }

    if {[regexp {([A-Z]*)} $data match polymer]} {
        continue
    }

    puts "Unparsed: $data"
}

# Get the initial pairs
# Store the first pair, which is needed later
for {set i 0} {$i < [string length $polymer] - 1} {incr i} {
    set pair [string range $polymer $i [expr $i + 1]]

    if {![info exists first_pair]} {
        set first_pair $pair
    }

    incr pairs($pair)
}

# Proc for doing one insertion step returns the new first pair
proc step {pairsname insertionname first_pair} {
    upvar 1 $pairsname pairs
    upvar 1 $insertionname insertion

    foreach {k v} [array get pairs] {
        if {[info exist insertion($k)]} {
            lassign [split $k ""] first second
            set insert $insertion($k)

            if {$k == $first_pair} {
                set first_pair $first$insert
            }

            incr pairs($first$insert) $v
            incr pairs($insert$second) $v
            incr pairs($first$second) -$v
        }
    }

    return $first_pair
}

# Calculate the most common element subtracted by the least common
proc max_sub_min {pairsname first_pair} {
    upvar 1 $pairsname pairs

    # Calculate the number of times an element exists
    foreach {k v} [array get pairs] {
        lassign [split $k ""] first second

        # Only for the first pair we add the value of the first
        # part of the pair
        if {$k == $first_pair} {
            incr count($first) $v
        }
        incr count($second) $v
    }

    # Put the values in a list
    foreach {k v} [array get count] {
        lappend values $v
    }

    # Sort the list decresending order
    set values [lsort -dec -integer $values]

    return [expr [lindex $values 0] - [lindex $values end]]
}

# Run for 40 steps
for {set i 0} {$i < 40} {incr i} {
    set first_pair [step pairs insertion $first_pair]

    if {$i == 9} {
        puts "After 10 steps: [max_sub_min pairs $first_pair]"
    }
}

puts "After 40 steps: [max_sub_min pairs $first_pair]"
