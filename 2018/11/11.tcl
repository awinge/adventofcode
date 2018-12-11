#!/usr/bin/tclsh

set serial 5235

# Calculate the power level in a coordinate
proc get_level {x y serial} {
    set rack_id [expr $x+10]
    set power_level [expr $rack_id * $y]
    set power_level [expr $power_level + $serial]
    set power_level [expr $power_level * $rack_id]
    set power_level [string index $power_level end-2]
    set power_level [expr $power_level -5]

    return $power_level
}

# Initialize the grid
for {set y 0} {$y <= 300} {incr y} {
    set row []
    for {set x 0} {$x <= 300} {incr x} {
        lappend row [get_level $x $y $serial]
    }
    lappend grid $row
}

# Get the max 3x3 quare in the grid
set max 0
for {set y 1} {$y < 297} {incr y} {
    for {set x 1} {$x <= 297} {incr x} {
        set square_power 0
        for {set gx $x} {$gx < [expr $x + 3]} {incr gx} {
            for {set gy $y} {$gy < [expr $y + 3]} {incr gy} {
                set power [lindex [lindex $grid $gy] $gx]
                           set square_power [expr $square_power + $power]
                       }
        }
        if {$square_power > $max} {
            set max $square_power
            set maxx $x
            set maxy $y
        }
    }
}

puts "Max 3x3 square starts at ($maxx,$maxy), with a value of $max."
puts "Answer: $maxx,$maxy"
puts ""

# Get the max of all square sizes
# Save the original grid and update the grid to new values size by size
# by adding the new squares
set orig_grid $grid
set max 0
for {set size 1} {$size <= 20} {incr size} {
    for {set y 1} {$y <= [expr 300 - $size]} {incr y} {
        for {set x 1} {$x <= [expr 300 - $size]} {incr x} {
            set square_power [lindex [lindex $grid $y] $x]
            if {$size > 1} {
                for {set gx $x} {$gx <= [expr $x + $size]} {incr gx} {
                    set power [lindex [lindex $orig_grid [expr $y + $size - 1]] $gx]
                    set square_power [expr $square_power + $power]
                }
                # -1 for not getting the corner twice
                for {set gy $y} {$gy <= [expr $y + $size - 1]} {incr gy} {
                    set power [lindex [lindex $orig_grid $gy] [expr $x + $size - 1]]
                    set square_power [expr $square_power + $power]
                }

                lset grid $y $x $square_power
            }
            if {$square_power > $max} {
                set max $square_power
                set maxx $x
                set maxy $y
                set maxsize $size
            }
        }
    }
}

puts "Max square is ${maxsize}x${maxsize} and starts at ($maxx,$maxy) with a value of $max."
puts "Answer: $maxx,$maxy,$maxsize"
