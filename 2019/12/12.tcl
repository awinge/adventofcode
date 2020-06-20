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
    if {[regexp {<x=([0-9-]*), y=([0-9-]*), z=([0-9-]*)>} $data match x y z]} {
        lappend position [list $x $y $z]
        lappend velocity [list 0  0  0]
    }
}

proc update_velocity {velocity pos} {
    for {set i 0} {$i < [expr [llength $velocity] - 1]} {incr i} {
        for {set j [expr $i + 1]} {$j < [llength $velocity]} {incr j} {
            set first_velocity [lindex $velocity $i]
            set first_position [lindex $pos $i]
            set second_velocity [lindex $velocity $j]
            set second_position [lindex $pos $j]

            for {set k 0} {$k < [llength $first_velocity]} {incr k} {
                set first_velocity_part [lindex $first_velocity $k]
                set first_position_part [lindex $first_position $k]
                set second_velocity_part [lindex $second_velocity $k]
                set second_position_part [lindex $second_position $k]

                if {$first_position_part < $second_position_part} {
                    incr first_velocity_part 1
                    incr second_velocity_part -1
                } elseif {$first_position_part > $second_position_part} {
                    incr first_velocity_part -1
                    incr second_velocity_part 1
                }

                set first_velocity [lreplace $first_velocity $k $k $first_velocity_part]
                set second_velocity [lreplace $second_velocity $k $k $second_velocity_part]
            }
            set velocity [lreplace $velocity $i $i $first_velocity]
            set velocity [lreplace $velocity $j $j $second_velocity]
        }
    }
    return $velocity
}

proc update_position {position velocity} {
    for {set i 0} {$i < [llength $position]} {incr i} {
        set planet [lindex $position $i]
        set vel    [lindex $velocity $i]

        set new_pos [lmap p $planet v $vel {expr {$p + $v}}]

        set position [lreplace $position $i $i $new_pos]
    }
    return $position
}

proc get_total_energy {position velocity} {
    set total 0
    for {set i 0} {$i < [llength $position]} {incr i} {
        set pos [lindex $position $i]
        set vel [lindex $velocity $i]

        set pot 0
        foreach p $pos {
            incr pot [expr abs($p)]
        }
        set kin 0
        foreach v $vel {
            incr kin [expr abs($v)]
        }

        set total [expr $total + ($pot * $kin)]
    }
    return $total
}


proc hash {position velocity coord} {
    foreach pos $position {
        lappend hash [lindex $pos $coord]
    }
    foreach vel $velocity {
        lappend hash [lindex $vel $coord]
    }
    return $hash
}

set history_x([hash $position $velocity 0]) 1
set history_y([hash $position $velocity 1]) 1
set history_z([hash $position $velocity 2]) 1

set i 0
while 1 {
    incr i
    set velocity [update_velocity $velocity $position]
    set position [update_position $position $velocity]
    
    if {$i == 1000} {
        puts "Total energy after 1000 steps: [get_total_energy $position $velocity]"
    }

    if {![info exists x_repeat]} {
        set hash_x [hash $position $velocity 0]
        
        if {[info exists history_x($hash_x)]} {
            set x_repeat $i
            array unset history_x
            puts "x: $x_repeat"
        } else {
            set history_x($hash_x) 1
        }
    }

    if {![info exists y_repeat]} {
        set hash_y [hash $position $velocity 1]
        
        if {[info exists history_y($hash_y)]} {
            set y_repeat $i
            array unset history_y
            puts "y: $y_repeat"
        } else {
            set history_y($hash_y) 1
        }
    }

    if {![info exists z_repeat]} {
        set hash_z [hash $position $velocity 2]
        
        if {[info exists history_z($hash_z)]} {
            set z_repeat $i
            array unset history_z
            puts "z: $z_repeat"
        } else {
            set history_z($hash_z) 1
        }
    }

    if {[info exists x_repeat] &&
        [info exists y_repeat] &&
        [info exists z_repeat]} {
        break
    }
}

proc gcd {a b} {
    if {$b > $a} {
        set t $a
        set a $b
        set b $t
    }

    if {$b == 0} {
        return $a
    }

    set c [expr $a % $b]
    set a $b
    set b $c

    return [gcd $a $b]
}

set steps [expr $x_repeat * $y_repeat * $z_repeat]
set steps [expr $steps / ([gcd $x_repeat $y_repeat] * [gcd $y_repeat $z_repeat])]

puts "First repeat after $steps steps."
