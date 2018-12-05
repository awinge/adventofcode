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

proc react {data remove} {
    set data [string map -nocase [list $remove ""] $data]

    set data [split $data ""]
    for {set i 0} {$i < [expr [llength $data] - 1]} {incr i} {
        set a [lindex $data $i]
        set b [lindex $data [expr $i + 1]]
        
        if {[string match -nocase $a $b] && ![string match $a $b]} {
            set data [lreplace $data $i [expr $i+1]]
            set removal 1
            set i [expr $i - 2]
        }
    }
    return [llength $data]
}


puts "Remaining units: [react $indata ""]"

set alpha {a b c d e f g h i j k l m n o p q r s t u v w x y z}

foreach char $alpha {
    set length [react $indata $char]
    
    if {![info exist min_length] || $length < $min_length} {
        set min_length $length
        set min_char $char
    }
}

puts "Remaining units: $min_length with $min_char removed"

