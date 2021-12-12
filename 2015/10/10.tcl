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

# Process for doing one iteration of look-and-say
proc look_and_say {digits} {
    set digits [split $digits ""]

    set repeats 1
    for {set i 0} {$i < [llength $digits]} {incr i} {
        set num [lindex $digits $i]

        if {[info exist last]} {
            if {$last == $num} {
                incr repeats
            } else {
                lappend result $repeats $last
                set repeats 1
            }
        }

        set last $num
    }
    lappend result $repeats $last

    return [join $result ""]
}

set digits $indata

for {set i 0} {$i < 40} {incr i} {
    set digits [look_and_say $digits]
}

puts "Length after 40 iterations: [string length $digits]"

for {set i 0} {$i < 10} {incr i} {
    set digits [look_and_say $digits]
}

puts "Length after 50 iterations: [string length $digits]"
