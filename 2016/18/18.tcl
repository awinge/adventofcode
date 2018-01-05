#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	lappend indata [regexp -inline -all -- {\S+} $row]
    }
}

proc trap_or_not {l c r} {
    switch ${l}${c}${r} {
        ^^. -
        .^^ -
        ^.. -
        ..^ { return ^ }
    }
    return .
}

proc next_row {data} {
    set previous [lindex $data end]

    set left .
    set center [string index $previous 0]
    set right [string index $previous 1]

    append next_row [trap_or_not $left $center $right]

    for {set i 1} {$i < [string length $previous]} {incr i} {
        set left $center
        set center $right
        if {$i == [expr [string length $previous] - 1]} {
            set right .
        } else {
            set right [string index $previous [expr $i + 1]]
        }

        append next_row [trap_or_not $left $center $right]
    }
    return $next_row
}
                  
        
set safe_tiles [regexp -all {\.} $indata]

for {set i 1} {$i < 40} {incr i} {
    set indata [next_row $indata]
    set safe_tiles [expr $safe_tiles + [regexp -all {\.} $indata]]
}

puts "Safe tiles after 40 rows: $safe_tiles"

for {set i 40} {$i < 400000} {incr i} {
    set indata [next_row $indata]
    set safe_tiles [expr $safe_tiles + [regexp -all {\.} $indata]]
}

puts "Safe tiles after 400000 rows: $safe_tiles"
