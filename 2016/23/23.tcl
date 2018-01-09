#!/usr/bin/tclsh

# Read the file
set fp [open "fastinput" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	set indata [lappend indata [regexp -inline -all -- {\S+} $row]]
    }
}
set debug 0

proc toggle_instr {offset} {
    upvar 1 indata indata

    set instr [lindex $indata $offset]

    set instr [string map {inc dec dec inc tgl inc} $instr]
    set instr [string map {jnz cpy cpy jnz} $instr]

    lset indata $offset $instr
}
    
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

    if {[regexp {jnz ([-0-9]+) ([a-d])} $instr _match value reg]} {
        set parsed 1
        if {$value != 0} {
            if {![info exists regs($reg)]} {
                set regs($reg) 0
            }
            set cur [expr $cur + $regs($reg) - 1]
        }
        
    }

    if {[regexp {tgl ([a-d]+)} $instr _match reg]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        set tindex [expr $cur + $regs($reg)]
        if {$tindex >= 0 && $tindex < [llength $indata]} {
            toggle_instr $tindex
        }
    }

    if {[regexp {mul ([a-d]) ([a-d])} $instr _match rega regb]} {
        set parsed 1
        if {![info exists regs($rega)]} {
            set regs($rega) 0
        }
        if {![info exists regs($regb)]} {
            set regs($regb) 0
        }
        set regs($rega) [expr $regs($rega) * $regs($regb)]
    }

    if {[regexp {mul ([a-d]) ([-0-9]+)} $instr _match reg value]} {
        set parsed 1
        if {![info exists regs($reg)]} {
            set regs($reg) 0
        }
        set regs($reg) [expr $regs($reg) * $value]
    }

    if {[regexp {nop} $instr]} {
        set parsed 1
    }

    incr cur

    if {$parsed == 0} {
        puts $instr
        puts "NOT parsed"
        exit
    }
}

set orig_indata $indata

set cur1 0
set regs1(a) 7

while {$cur1 >= 0 && $cur1 < [llength $indata]} {
    run_instr regs1 cur1
}

puts "The value of register a is: $regs1(a)"


set indata $orig_indata
set cur2 0
set regs2(a) 12

while {$cur2 >= 0 && $cur2 < [llength $indata]} {
    run_instr regs2 cur2
}

puts "The value of register a is: $regs2(a)"
