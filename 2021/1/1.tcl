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

# Loop through the data and check the new value against the saved value
# Special case for the first value where it is just saved

set first     1
set increased 0
foreach data $indata {
    if {$first} {
        set first 0
    } else {
        if {$data > $last} {
            incr increased
        }
    }
    set last $data
}

puts "The number of increasing depths: $increased"


# Loop through the valid sliding windows starting at position i where the
# windows are i..i+2 and i+1..1+3.
# Compare the first window sum with the second window sum

set increased 0
for {set i 0} {$i < [expr [llength $indata] - 3]} {incr i} {
    set first [expr [join [lrange $indata $i [expr $i + 2]] +]]
    set second [expr [join [lrange $indata [expr $i + 1] [expr $i + 3]] +]]

    if {$second > $first} {
        incr increased
    }
}

puts "The number of increading sliding window depths: $increased"
