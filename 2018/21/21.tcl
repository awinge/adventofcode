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

# Parse the input program and which reg is connected to the instruction pointer
foreach data $indata {
    if {[regexp {([\w]*) ([\d]*) ([\d]*) ([\d]*)} $data _match op a b c]} {
        lappend program [list $op $a $b $c]
    }

    regexp {\#ip ([\d]*)} $data _match ip_reg
}

# One proc per possible instruction
proc addr {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] + [lindex $regs $b]]
    return $regs
}

proc addi {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] + $b]
    return $regs
}

proc mulr {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] * [lindex $regs $b]]
    return $regs
}

proc muli {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] * $b]
    return $regs
}

proc banr {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] & [lindex $regs $b]]
    return $regs
}

proc bani {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] & $b]
    return $regs
}

proc borr {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] | [lindex $regs $b]]
    return $regs
}

proc bori {regs instr} {
    lassign $instr op a b c

    lset regs $c [expr [lindex $regs $a] | $b]
    return $regs
}

proc setr {regs instr} {
    lassign $instr op a b c

    lset regs $c [lindex $regs $a]
    return $regs
}

proc seti {regs instr} {
    lassign $instr op a b c

    lset regs $c $a
    return $regs
}

proc gtir {regs instr} {
    lassign $instr op a b c

    if {$a > [lindex $regs $b]} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

proc gtri {regs instr} {
    lassign $instr op a b c

    if {[lindex $regs $a] > $b} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

proc gtrr {regs instr} {
    lassign $instr op a b c

    if {[lindex $regs $a] > [lindex $regs $b]} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

proc eqir {regs instr} {
    lassign $instr op a b c

    if {$a == [lindex $regs $b]} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

proc eqri {regs instr} {
    lassign $instr op a b c

    if {[lindex $regs $a] == $b} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

proc eqrr {regs instr} {
    lassign $instr op a b c

    if {[lindex $regs $a] == [lindex $regs $b]} {
        lset regs $c 1
    } else {
        lset regs $c 0
    }
    return $regs
}

# Returns the som of all divider of num
proc sum_dividers {num} {
    for {set i 1} {$i <= $num} {incr i} {
        if {[expr $num % $i] == 0} {
            incr sum $i
        }
    }
    return $sum
}

# Execute the program
proc execute {program regs ip_reg} {
    set first 1
    set ip 0
    while 1 {
        # Set the ip_reg before execution
        if {$ip < 0 || $ip >= [llength $program]} {
            return $regs
        }

        # Intercept the comparison with R0
        if {$ip == 28} {
            set r1 [lindex $regs 1]
            if {$first == 1} {
                set least $r1
                puts "Fewest instructions R0: $r1"
                set first 0
            }
            # Check the first time we get the same value a second time
            if {[info exists visited($r1)]} {
                puts "Most instructions R0: $last"
                exit
            }
            set visited($r1) 1
            set last $r1
        }
        # Start of algorithm that integer divides with 256.
        # Just skip it and jump back
        if {$ip == 17} {
            lset regs 2 [expr [lindex $regs 2] / 256]
            set ip 8
        }
        lset regs $ip_reg $ip
        set instruction [lindex $program $ip]
        lassign $instruction op a b c
        set regs [$op $regs $instruction]
        if {$c == $ip_reg} {
            set ip [lindex $regs $ip_reg]
        }
        incr ip
    }
}

# Initialize regs and run the program
set regs [list 0 0 0 0 0 0]
set regs [execute $program $regs $ip_reg]
