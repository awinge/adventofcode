#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	set indata [lappend indata [regexp -inline -all -- {\S+} $row]]
    }
}
set debug 0

# retuns {waiting sent}
proc run_instr {regsname curname} {
    upvar 1 $regsname regs
    upvar 1 $curname cur
    upvar 1 debug debug
    upvar 1 indata indata

    set parsed 0
    set instr [lindex $indata $cur]
    if {$debug} { puts $instr }

    if {[regexp {inc ([a-d])} $instr _match reg]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        set regs($reg) [expr $regs($reg) + 1]
    }

    if {[regexp {dec ([a-d])} $instr _match reg]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        set regs($reg) [expr $regs($reg) - 1]
    }

    if {[regexp {cpy ([a-d]) ([a-d])} $instr _match srcreg dstreg]} {
        set parsed 1
        if {![info exists regs($srcreg)]} {
            set regs($srcreg) 0
        }
        set regs($dstreg) $regs($srcreg)
    }

    if {[regexp {cpy ([-0-9]+) ([a-d])} $instr _match value dstreg]} {
        set parsed 1
        set regs($dstreg) $value
    }
    
    if {[regexp {jnz ([a-d]) ([-0-9]+)} $instr _match reg value]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        if {$regs($reg) != 0} {
            set cur [expr $cur + $value - 1]
        }
    }
    
    if {[regexp {jnz ([-0-9]+) ([-0-9]+)} $instr _match condvalue jmpvalue]} {
        set parsed 1
        if {$condvalue != 0} {
            set cur [expr $cur + $jmpvalue - 1]
        }
    }

    incr cur

    if {$parsed == 0} {
        puts $instr
        puts "NOT parsed"
        exit
    }
}

set cur1 0

while {$cur1 >= 0 && $cur1 < [llength $indata]} {
    run_instr regs1 cur1
}

puts "The value of register a is: $regs1(a)"

set cur2 0
set regs2(c) 1

while {$cur2 >= 0 && $cur2 < [llength $indata]} {
    run_instr regs2 cur2
}
puts "The value of register a is: $regs2(a)"
