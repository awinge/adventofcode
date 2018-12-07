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

# Parse input
foreach data $indata {
    if {[regexp {Step ([A-Z]) must be finished before step ([A-Z]) can begin.} $data _match before step]} {
        lappend req($step) $before
        lappend possible $before
    }
}

# Create the first possible list
foreach step $possible {
    if {[info exists req($step)]} {
        continue
    }
    lappend next_possible $step
}
set possible [lsort -unique $next_possible]

# Save input data to part two
array set orig_req [array get req]
set orig_possible $possible

# Proc to go through requirement and remove all occurances of the input
# It also adds items with no requirements to possible array
proc remove_req {char} {
    global req
    global possible
    
    foreach {key value} [array get req] {
        if {[info exists new_value]} {
            unset new_value
        }
        foreach v $value {
            if {$v != $char} {
                lappend new_value $v
            }
        }
        if {![info exist new_value]} {
            lappend possible $key
            unset req($key)
        } else {
            set req($key) $new_value
        }
    }
}

while {[llength $possible] > 0} {
    set possible [lsort -unique $possible]
    set char [lindex [lsort $possible] 0]
    set possible [lreplace $possible 0 0]
    lappend result $char

    remove_req $char
}

puts "Result: [join $result ""]"

array set req [array get orig_req]
set possible $orig_possible

set t 0
set workers 5
set base_cost 60

while {[llength [array get req]] > 0 || [llength $possible] > 0} {
    set possible [lsort -unique $possible]

    # Schedule work for all workers
    while {$workers > 0 && [llength $possible] > 0} {
        set char [lindex [lsort $possible] 0]
        set possible [lreplace $possible 0 0]
        set cost [expr $base_cost + [scan $char %c] - [scan A %c] + 1]

        lappend work [list $cost $char]
        set workers [expr $workers - 1]
    }

    # Do work that will finished first
    set work [lsort -index 0 $work]
    set done [lindex $work 0]
    set work [lreplace $work 0 0]
    set t [expr $t + [lindex $done 0]]

    # Deduct elapsed time from all other work in progress
    for {set i 0} {$i < [llength $work]} {incr i} {
        set w [lindex $work $i]
        
        lset w 0 [expr [lindex $w 0] - [lindex $done 0]]
        set work [lreplace $work $i $i $w]
    }

    # Remove requirement for the work finished
    remove_req [lindex $done 1]

    # A worker is now available
    incr workers
}

puts "Time: $t"
