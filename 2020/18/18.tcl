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

# Evaluation function part 1
proc evaluate {m} {
    while 1 {
        # If a parenthesis is found. Evaluate that first recurively and substitute in the answer
        if {[regexp {([0-9+* ()]*)\(([0-9+* ]*)\)([0-9+* ()]*)} $m match left inside right]} {
            set m "${left}[evaluate $inside]${right}"
            continue
        }

        # Evaluate left to right no matter addition of multiplication and substitute in the answer
        if {[regexp {([0-9]*) *(\+|\*) *([0-9]*)(.*)} $m match num1 op num2 rest]} {
            set value [expr $num1 $op $num2]
            set m "${value}${rest}"
            continue
        }

        # By now the answer should possible to return i.e. just a number
        return $m
    }
}

# Evaluation function part 2
proc evaluate2 {m} {
    while 1 {
        # If a parenthesis is found. Evaluate that first recurively and substitute in the answer
        if {[regexp {([0-9+* ()]*)\(([0-9+* ]*)\)([0-9+* ()]*)} $m match left inside right]} {
            set m "${left}[evaluate2 $inside]${right}"
            continue
        }

        # Addition has preference
        if {[regexp {(|[0-9+* ()]* )([0-9]+) *(\+) *([0-9]+)( [0-9+* ()]*|)} $m match left num1 op num2 right]} {
            set value [expr $num1 $op $num2]
            set m "${left}${value}${right}"
            continue
        }

        # Multiplication
        if {[regexp {(|[0-9+* ()]* )([0-9]+) *(\*) *([0-9]+)( [0-9+* ()]*|)} $m match left num1 op num2 right]} {
            set value [expr $num1 $op $num2]
            set m "${left}${value}${right}"
            continue
        }

        # By now the answer should possible to return i.e. just a number
        return $m
    }
}

set sum 0
foreach data $indata {
    incr sum [evaluate $data]
}
puts "The sum after evaluation: $sum"

set sum 0
foreach data $indata {
    incr sum [evaluate2 $data]
}
puts "The sum after evaluation: $sum"
