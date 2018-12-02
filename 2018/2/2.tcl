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

set pairs    0
set triplets 0

# Loop through all searching for pairs and triplets
foreach data $indata {
    set data [split $data ""]

    set p 0
    set t 0
    foreach letter $data {
        set matches [lsearch -all $data $letter]

        if {[llength $matches] == 2} {
            set p 1
        }
        if {[llength $matches] == 3} {
            set t 1
        }
    }

    set pairs [expr $pairs + $p]
    set triplets [expr $triplets + $t]
}

puts "Checksum: [expr $pairs * $triplets]"

# Compare function that returns the index where the only
# diff is, otherwise it returns -1
# Assumes equal lengths of inputs
proc compare {a b} {
    set diffs 0
    set a [split $a ""]
    set b [split $b ""]

    for {set i 0} {$i < [llength $a]} {incr i} {
        if {[lindex $a $i] != [lindex $b $i]} {
            incr diffs
            set diff_index $i
        }
    }

    if {$diffs == 1} {
        return $diff_index
    } else {
        return -1
    }
}

for {set i 0} {$i < [expr [llength $indata] - 1]} {incr i} {
    for {set j [expr $i + 1]} {$j < [llength $indata]} {incr j} {
        set a [lindex $indata $i]
        set b [lindex $indata $j]

        set diff_index [compare $a $b]
        if {$diff_index != -1} {
            puts "The common string is: [string replace $a $diff_index $diff_index]"
        }
    }
}
