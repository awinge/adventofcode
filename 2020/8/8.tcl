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

# Returncodes
# 0 - program terminated
# 1 - program loop detected
proc execute {program} {
    upvar 1 acc acc

    set ip 0
    set acc 0
    while 1 {
        if {[info exist executed($ip)]} {
            return 1
        }

        set executed($ip) 1

        if {$ip < 0 || $ip >= [llength $program]} {
            return 0
        }

        set inst [lindex $program $ip]

        if {[regexp {jmp ([0-9\+\-]*)} $inst match val]} {
            incr ip $val
            continue
        }

        if {[regexp {acc ([0-9\+\-]*)} $inst match val]} {
            incr acc $val
            incr ip
            continue
        }

        if {[regexp {nop ([0-9\+\-]*)} $inst match val]} {
            incr ip
            continue
        }

        puts "Did not parse: $inst"
        exit
    }
}

execute $indata
puts "Accumulator when looping: $acc"

# Check position for jmp or nop otherwise check next instruction
# Swap the instruction
# Execute program
# If program terminates break
# Otherwise put the old instrunction back and check next instruction
set alterpos 0
while 1 {
    set altinst [lindex $indata $alterpos]

    if {[regexp {jmp ([0-9\+\-]*)} $altinst match val]} {
        set indata [lreplace $indata $alterpos $alterpos "nop $val"]
        if {[execute $indata] == 0} {
            break
        } else {
            set indata [lreplace $indata $alterpos $alterpos "jmp $val"]
        }
    }

    if {[regexp {nop ([0-9\+\-]*)} $altinst match val]} {
        set indata [lreplace $indata $alterpos $alterpos "jmp $val"]
        if {[execute $indata] == 0} {
            break
        } else {
            set indata [lreplace $indata $alterpos $alterpos "nop $val"]
        }
    }

    incr alterpos
    if {$alterpos >= [llength $indata]} {
        puts "Tried alterating all instructions, giving up"
        exit
    }
}

puts "Alterating instruction \"$altinst\" at posision $alterpos"
puts "Accumulator when terminating: $acc"
