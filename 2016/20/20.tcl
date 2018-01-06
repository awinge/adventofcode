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

foreach data $indata {
    set start_stop [split $data "-"]
    lappend blocks [list [lindex $start_stop 0] [lindex $start_stop 1]]
}
set blocks [lsort -index 0 -integer $blocks]

proc find_ips {blocks} {
    set unblocked 0
    set attempt 0
    foreach block $blocks {
        if {$attempt >= [lindex $block 0] && $attempt <= [lindex $block 1]} {
            set attempt [expr max($attempt, [lindex $block 1] + 1)]
        } else {
            if {$attempt < [lindex $block 0]} {
                if {![info exists first]} {
                    set first $attempt
                }
                set unblocked [expr $unblocked + ([lindex $block 0] - $attempt)]
                set attempt [expr [lindex $block 1] + 1]
            }
        }
    }
    return [list $first $unblocked]
}


set find_return [find_ips $blocks]

puts "First unblocked: [lindex $find_return 0]"
puts "Number unblocked: [lindex $find_return 1]"
