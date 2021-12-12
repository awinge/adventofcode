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
    incr tot_code [string length $data]
    incr tot_mem  [string length [expr $data]]

    set encode \"
    foreach char [split $data ""] {
        switch $char {
            \" {
                append encode \\\"
            }

            \\ {
                append encode \\\\
                }

            default {
                append encode $char
            }
        }
    }
    append encode \"

    incr tot_encode [string length $encode]
}

puts "Answer: [expr $tot_code - $tot_mem]"
puts "Answer: [expr $tot_encode - $tot_code]"
