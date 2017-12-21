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

foreach data $indata {
    regexp {p=<([-0-9]+),([-0-9]+),([-0-9]+)>, v=<([-0-9]+),([-0-9]+),([-0-9]+)>, a=<([-0-9]+),([-0-9]+),([-0-9]+)>} $data _match px py pz vx vy vz ax ay az
    lappend points [list [list $px $py $pz] [list $vx $vy $vz] [list $ax $ay $az] 0]
}

proc update_all {points} {
    foreach point $points {
        for {set axis 0} {$axis < 3} {incr axis} {
            lset point 1 $axis [expr [lindex $point 1 $axis] + [lindex $point 2 $axis]]
            lset point 0 $axis [expr [lindex $point 0 $axis] + [lindex $point 1 $axis]]
        }
        lappend return_points $point
    }
    return $return_points
}

proc update_collision {points} {
    for {set i 0} {$i < [expr [llength $points] - 1]} {incr i} {
        for {set j [expr $i + 1]} {$j < [llength $points]} {incr j} {
            if {[lindex $points $i 0] == [lindex $points $j 0]} {
                lset points $i 3 1
                lset points $j 3 1
            }
        }
    }
    return $points
}

proc get_manhattan {points} {
    foreach point $points {
        lappend manhattan [expr abs([lindex $point 0 0]) + abs([lindex $point 0 1]) + abs([lindex $point 0 2])]
    }
    return $manhattan
}


set acc_manhattan [get_manhattan $points]

for {set i 0} {$i < 500} {incr i} {
    set points [update_collision $points]
    set points [update_all $points]
    set manhattan [get_manhattan $points]
    for {set m 0} {$m < [llength $acc_manhattan]} {incr m} {
        lset acc_manhattan $m [expr [lindex $acc_manhattan $m] + [lindex $manhattan $m]]
    }
}

set min_index 0
set min [lindex $acc_manhattan 0]
for {set m 1} {$m < [llength $acc_manhattan]} {incr m} {
    if {[lindex $acc_manhattan $m] < $min} {
        set min_index $m
        set min [lindex $acc_manhattan $m]
    }
}

puts "Particle that stays closest to origo: $min_index"


set particles 0
foreach point $points {
    if {[lindex $point 3] == 0} {
        incr particles
    }
}

puts "Particles left: $particles"


