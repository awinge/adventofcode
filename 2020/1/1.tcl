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

proc find_two {sum numbers} {
    for {set i 0} {$i < [expr [llength $numbers] - 1]} {incr i} {
        for {set j [expr $i + 1]} {$j < [llength $numbers]} {incr j} {
            set first  [lindex $numbers $i]
            set second [lindex $numbers $j]

            if {[expr $first + $second] == $sum} {
                return [expr $first * $second]
            }
        }
    }
}

proc find_three {sum numbers} {
    for {set i 0} {$i < [expr [llength $numbers] - 2]} {incr i} {
        for {set j [expr $i + 1]} {$j < [expr [llength $numbers] - 1]} {incr j} {
            for {set k [expr $j + 1]} {$k < [llength $numbers]} {incr k} {
                set first  [lindex $numbers $i]
                set second [lindex $numbers $j]
                set third  [lindex $numbers $k]

                if {[expr $first + $second + $third] == 2020} {
                    return [expr $first * $second * $third]
                }
            }
        }
    }
}

puts "First part:  [find_two 2020 $indata]"
puts "Second part: [find_three 2020 $indata]"
