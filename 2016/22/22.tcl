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

set xmin 0
set ymin 0
set xmax 33
set ymax 29

foreach data $indata {
    if {[regexp {/dev/grid/node-x([0-9]*)-y([0-9]*) *([0-9]*)T *([0-9]*)T *([0-9]*)T} $data _match x y size used avail]} {
        incr num
        lappend column [list $num $size $used $avail]
        if {$y == $ymax} {
            lappend grid $column
            unset column
        }
    }
}

proc get_viable_pairs {grid} {
    set pairs 0
    foreach a_col $grid {
        foreach a $a_col {
            foreach b_col $grid {
                foreach b $b_col {
                    if {[lindex $a 0] == [lindex $b 0]} {
                        continue
                    }
                    if {[lindex $a 2] == 0} {
                        continue
                    }
                    if {[lindex $b 3] >= [lindex $a 2]} {
                        incr pairs
                    }
                }
            }
        }
    }
    return $pairs
}

proc get_adjacent {grid x y} {
    global xmin
    global xmax
    global ymin
    global ymax

    # Left
    if {[expr $x - 1] >= $xmin} {
        lappend ret [list [expr $x - 1] $y]
    }
    # Right
    if {[expr $x + 1] <= $xmax} {
        lappend ret [list [expr $x + 1] $y]
    }
    # Up
    if {[expr $y - 1] >= $ymin} {
        lappend ret [list $x [expr $y - 1]]
    }
    # Down
    if {[expr $y + 1] <= $ymax} {
        lappend ret [list $x [expr $y + 1]]
    }
    return $ret
}
        
proc get_viable_adjacent_pairs {grid} {
    global xmin xmax ymin ymax
    
    set pairs 0
    for {set x $xmin} {$x <= $xmax} {incr x} {
        for {set y $ymin} {$y <= $ymax} {incr y} {
            foreach {to_x to_y} [join [get_adjacent $grid $x $y]] {

                if {[lindex $grid $x $y 2] > 0 &&
                    [lindex $grid $to_x $to_y 3] >= [lindex $grid $x $y 2]} {

                    puts "Possible to move $x:$y to $to_x:$to_y"
                    incr pairs
                }
            }
        }
    }
}

puts "Number of viable pairs: [get_viable_pairs $grid]"

get_viable_adjacent_pairs $grid

# After analysing the grid it seems like we just need to use the only empty space to
# move data around.
# Also noting the "wall" along y=2 only openings on x=0 and x=1

# Empty space in my case was 4:25,
# Going moving the empty space left to y=1 (to go through the "wall") 3 steps (1:25)
# Going all the way to the top 25 steps (1:0)
# Going all the way to the right 32 steps (33:0) (Also moving wanted data to left)
# Moving data the wanted data one step to the left requires 5 steps with the empty space
# The wanted data needs to move an additional 32 steps
# I.e. 3 + 25 + 32 + 5*32

puts "Minimum amount of steps: [expr 3 + 25 + 32 + 5*32]"
