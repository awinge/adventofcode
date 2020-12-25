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

lassign $indata card door

set subj 7
set mod 20201227

set value 1
set i 0
while {$value != $card} {
    incr i
    set value [expr ($value * $subj) % $mod]
}

set card_loop $i

set value 1
for {set i 0} {$i < $card_loop} {incr i} {
    set value [expr ($value * $door) % $mod]
}

puts "Encryption key: $value"
