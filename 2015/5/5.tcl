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

set nice 0
foreach data $indata {
    set vowels 0
    set double 0

    if {[info exists last]} {
        unset last
    }

    # Check for forbidden strings
    if {[regexp {.*(ab|cd|pq|xy).*} $data match]} {
        continue
    }

    # Loop through all letters
    foreach char [split $data ""] {

        # Count vowels
        switch $char {
            a -
            e -
            i -
            o -
            u {
                incr vowels
            }
        }

        # Check it the last char matches the current
        if {[info exists last] && $char == $last} {
            set double 1
        }

        set last $char
    }

    # Nice words have at least 3 vowels and a double char
    if {$vowels >= 3 && $double} {
        incr nice
    }
}

puts "Number of nice strings: $nice"


set nice 0
foreach data $indata {
    # Check for pair of letters occuring more than once
    set pair 0
    for {set i 0} {$i < [string length $data] - 3} {incr i} {
        for {set j [expr $i + 2]} {$j < [string length $data] - 1} {incr j} {
            set first [string range $data $i [expr $i + 1]]
            set second [string range $data $j [expr $j + 1]]

            if {$first == $second} {
                set pair 1
            }
        }
    }

    # Check for repeating letters with one letter in between
    set repeat 0
    for {set i 0} {$i < [string length $data] - 2} {incr i} {
        set first [string index $data $i]
        set second [string index $data [expr $i + 2]]

        if {$first == $second} {
            set repeat 1
        }
    }

    if {$pair && $repeat} {
        incr nice
    }
}

puts "Number of nice strings: $nice"
