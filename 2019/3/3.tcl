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


set wire 0
set map(0,0) o

foreach data $indata { 
    set x 0
    set y 0
    incr wire
    set steps 0
    
    foreach instruction [split $data ","] {
        regexp {([DURL])([0-9]*)} $instruction _match dir num

        for {set i 0} {$i < $num} {incr i} {
            switch $dir {
                U {
                    incr y 1
                }
                D {
                    incr y -1
                }
                L {
                    incr x -1
                }
                R {
                    incr x 1
                }
            }

            incr steps
            
            if {[info exists map($x,$y)] && $wire != [lindex $map($x,$y) 0]} {
                set total_steps [expr [lindex $map($x,$y) 1] + $steps]
                set map($x,$y) [list X $total_steps]

                if {![info exists least_manhattan] || [expr abs($x) + abs($y) < $least_manhattan]} {
                    set least_manhattan [expr abs($x) + abs($y)]
                }
                if {![info exists least_steps] || [expr $total_steps < $least_steps]} {
                    set least_steps $total_steps
                }
            } else {
                set map($x,$y) [list $wire $steps]
            }
        }
    }
}

puts "Least manhattan to central point:  $least_manhattan"
puts "Least steps to reach intersection: $least_steps"
