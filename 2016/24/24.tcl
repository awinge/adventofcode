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

# Parse the input to create list of lists to represent the mace
foreach data $indata {
    lappend mace [split $data ""]
}


# Loop though the mace and find all the numbers and corresponding coordinates
set r 0
foreach row $mace {
    set c 0
    foreach char $row { 
        if {[string is digit $char]} {
            lappend numbers [list $char $c $r]
        }
        incr c
    }
    incr r
}
set numbers [lsort $numbers]

# From a mace and a coordinate, give a list of possible movements
proc get_possible_directions {mace x y} {
    if {[expr $x + 1] < [llength [lindex $mace $y]] &&
        [lindex [lindex $mace $y] [expr $x + 1]] != "#"} {
        lappend result "R"
    }

    if {[expr $x - 1] >= 0 &&
        [lindex [lindex $mace $y] [expr $x - 1]] != "#"} {
        lappend result "L"
    }

    if {[expr $y + 1] < [llength $mace] &&
        [lindex [lindex $mace [expr $y + 1] $x]] != "#"} {
        lappend result "D"
    }
    if {[expr $y - 1] >= 0 &&
        [lindex [lindex $mace [expr $y - 1] $x]] != "#"} {
        lappend result "U"
    }
    return $result
}

# Print the mace (only for debug)
proc print_mace {mace} {
    foreach row $mace {
        puts [join $row ""]
    }
}

# Calculate the manhattan distance between two coordinates
proc manhattan {x y gx gy} {
    return [expr abs($gy - $y) + abs($gx - $x)]
}

# Check if a coordinate exists in a list and return the index
proc in_open {x y open_list} {
    for {set i 0} {$i < [llength $open_list]} {incr i} { 
        set l [lindex $open_list $i]
        set lx [lindex $l 3]
        set ly [lindex $l 4]

        if {$lx == $x && $ly == $y} {
            return $i
        }
    }
    return -1
}
       
# Implements A*
proc traverse {mace x y gx gy} {
    set g 0
    set h [manhattan $x $y $gx $gy]
    set f [expr $g + $h]
    set open_list [list [list $f $g $h $x $y]]

    set finished 0
    while {[llength $open_list] > 0} {
        set node [lindex $open_list 0]
        set cf [lindex $node 0]
        set cg [lindex $node 1]
        set ch [lindex $node 2]
        set cx [lindex $node 3]
        set cy [lindex $node 4]

        if {$cx == $gx && $cy == $gy} {
            set finished 1
        }
        
        set possible_directions [get_possible_directions $mace $cx $cy]
        
        foreach direction $possible_directions {
            if {$direction == "R"} {
                set x [expr $cx + 1]
                set y $cy
            }
            if {$direction == "L"} {
                set x [expr $cx - 1]
                set y $cy
            }
            if {$direction == "D"} {
                set x $cx
                set y [expr $cy + 1]
            }
            if {$direction == "U"} {
                set x $cx
                set y [expr $cy - 1]
            }
            set g [expr $cg + 1]
            set h [manhattan $x $y $gx $gy]
            set f [expr $g + $h]
            
            if {[info exists closed(x${x}y${y})]} {
                set closed_node $closed(x${x}y${y})
                set closed_f [lindex $closed_node 0]
                if {$f < $closed_f} {
                    lappend open_list [list $f $g $h $x $y]
                    unset closed(x${x}y${y})
                }
            } else {
                set open_index [in_open $x $y $open_list]
                if {$open_index != -1} {
                    set open_node [lindex $open_list $open_index]
                    set open_f [lindex $open_node 0]
                    if {$f < $open_f} {
                        set open_list [lreplace $open_list $open_index $open_index]
                        lappend open_list [list $f $g $h $x $y]
                    }
                } else {
                    lappend open_list [list $f $g $h $x $y]
                }
            }
        }

        set closed(x${cx}y${cy}) [list $cf $cg $ch]
        set open_list [lreplace $open_list 0 0]
        set open_list [lsort -index 0 $open_list]
    }

    if {$finished == 1} {
        set goal_node $closed(x${gx}y${gy})
        return [lindex $goal_node 1]
    } else {
        return 0
    }
    
}

# Calculate distances between all node combinations
for {set origin 0} {$origin < [expr [llength $numbers] - 1]} {incr origin} {
    for {set goal [expr $origin + 1]} {$goal < [llength $numbers]} {incr goal} {
        set origin_x [lindex [lindex $numbers $origin] 1]
        set origin_y [lindex [lindex $numbers $origin] 2]
        set goal_x [lindex [lindex $numbers $goal] 1]
        set goal_y [lindex [lindex $numbers $goal] 2]

        set move($origin$goal) [traverse $mace $origin_x $origin_y $goal_x $goal_y]
        set move($goal$origin) $move($origin$goal)
    }
}

# Gives all permutations of a list
proc permutations items {
    set l [llength $items]
    if {[llength $items] < 2} {
        return $items
    } else {
        for {set j 0} {$j < $l} {incr j} {
            foreach subcomb [permutations [lreplace $items $j $j]] {
                lappend res [concat [lindex $items $j] $subcomb]
            }
        }
        return $res
    }
}

# Create a list of all numbers excluding 0
foreach n $numbers {
    set num [lindex $n 0]
    if {$num != 0} {
        lappend perm_input $num
    }
}    

# Go through all permutations and look for the minimum distance (start with 0)
foreach perm [permutations $perm_input] {
    set steps 0
    set current 0
    foreach next $perm {
        set steps [expr $steps + $move(${current}${next})]
        set current $next
    }
    if {![info exists min_steps] || $steps < $min_steps} {
        set min_steps $steps
    }
}
puts "Minimum steps 0 to all: $min_steps"

# Go though all permutations again and look for the minimum distance (start and finish with 0)
unset min_steps
foreach perm [permutations $perm_input] {
    set steps 0
    set current 0
    foreach next $perm {
        set steps [expr $steps + $move(${current}${next})]
        set current $next
    }
    set steps [expr $steps + $move(${current}0)]
    if {![info exists min_steps] || $steps < $min_steps} {
        set min_steps $steps
    }
}
puts "Minimum steps 0 to all and back to 0: $min_steps"


    

    


    
