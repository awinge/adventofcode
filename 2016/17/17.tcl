#!/usr/bin/tclsh

package require md5

set testinput ihgpwlah
set input     qtetzkpl


set xpos 0
set ypos 0

proc get_door_state {hash} {
    switch -regexp -- $hash {
        [0-9aA]  { return 0 }
        [b-fB-F] { return 1 }
    }
}

proc get_doors_states {indata path} {
    set md5sum [md5::md5 -hex "${indata}${path}"]
    for {set i 0} {$i < 4} {incr i} {
        lappend states [get_door_state [string index $md5sum $i]]
    }
    return $states
}

proc get_valid_paths {x y} {
    lappend valid_paths [expr $y > 0]
    lappend valid_paths [expr $y < 3]
    lappend valid_paths [expr $x > 0]
    lappend valid_paths [expr $x < 3]
}

proc is_vault {x y} {
    if {$x == 3 && $y == 3} {
        return 1
    } else {
        return 0
    }
}

proc is_valid_pos {x y} {
    if {$x >= 0 && $x <= 3 &&
        $y >= 0 && $y <= 3} {
        return 1
    } else {
        return 0
    }
}

set minsteps 10000
set maxsteps 0
proc step_through {input x y path steps} {
    global minsteps
    global minpath
    global maxsteps
    global maxpath

    if {![is_valid_pos $x $y]} {
        return
    }
    if {[is_vault $x $y]} {
        if {$steps > $maxsteps} {
            set maxsteps $steps
            set maxpath $path
        }
        if {$steps < $minsteps} {
            set minsteps $steps
            set minpath $path
        }
        return
    }
    set possible_paths [get_doors_states $input $path]

    set up    [lindex $possible_paths 0]
    set down  [lindex $possible_paths 1]
    set left  [lindex $possible_paths 2]
    set right [lindex $possible_paths 3]

    incr steps
    if {$up} {
        step_through $input $x [expr $y - 1] "${path}U" $steps
    }
    if {$down} {
        step_through $input $x [expr $y + 1] "${path}D" $steps
    }
    if {$left} {
        step_through $input [expr $x - 1] $y "${path}L" $steps
    }
    if {$right} {
        step_through $input [expr $x + 1] $y "${path}R" $steps
    }
}

step_through $input 0 0 "" 0

puts "Minimum steps: $minsteps"
#puts $minpath

puts "Maximum steps: $maxsteps"
#puts $maxpath
