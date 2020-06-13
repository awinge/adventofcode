#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd ","] {
    if {$row != ""} {
	lappend indata [regexp -inline -all -- {\S+} $row]
    }
}

# PART ONE
proc execute {program noun verb} {
    set ip 0

    set program [lreplace $program 1 1 $noun]
    set program [lreplace $program 2 2 $verb]

    while 1 {
        switch [lindex $program $ip] {
            1 {
                set param1 [lindex $program [expr $ip + 1]]
                set param2 [lindex $program [expr $ip + 2]]
                set calculation [expr [lindex $program $param1] + [lindex $program $param2]]
            }
            2 { 
                set param1 [lindex $program [expr $ip + 1]]
                set param2 [lindex $program [expr $ip + 2]]
                set calculation [expr [lindex $program $param1] * [lindex $program $param2]]
            }
            99 {
                return $program 
            }
            default {
                puts "Something is wrong"
                exit
            }
        }
        
        set param3 [lindex $program [expr $ip + 3]]
        set program [lreplace $program $param3 $param3 $calculation]
        incr ip 4
    }
}

set program [execute $indata 12 2]
puts "Position 0 after halt: [lindex $program 0]"

#PART TWO
set wanted_output 19690720

for {set noun 0} {$noun <= 99} {incr noun} {
    for {set verb 0} {$verb <= 99} {incr verb} {
        set program [execute $indata $noun $verb]
        if {[lindex $program 0] == $wanted_output} {
            puts "100 * noun + verb: [expr 100 * $noun + $verb]"
            exit
        }
    }
}

puts "Something is wrong"
