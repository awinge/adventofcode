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

# Parse the input and save all coodinates as a list of [x y]
foreach data $indata {
    if {[regexp {([[:digit:]]*), ([[:digit:]]*)} $data _match x y]} {
        lappend coords [list $x $y]
    }
}

# Proc to get the min and max x and y as a list
proc minmax_xy {coords} {
    foreach coord $coords {
        set x [lindex $coord 0]
        set y [lindex $coord 1]
        if {![info exists minx] || $x < $minx} {
            set minx $x
        }
        if {![info exists maxx] || $x > $maxx} {
            set maxx $x
        }
        if {![info exists miny] || $y < $miny} {
            set miny $y
        }
        if {![info exists maxy] || $y > $maxy} {
            set maxy $y
        }
    }
    return [list $minx $maxx $miny $maxy]
}

lassign [minmax_xy $coords] minx maxx miny maxy

# Calculate the manhattan distance
proc manhattan {x1 y1 x2 y2} {
    return [expr abs($x2 - $x1) + abs($y2 - $y1)]
}

# Create the grid
# Put in numbers where a coodinate has exclusive minimal manhattan distance
for {set y $miny} {$y <= $maxy} {incr y} {
    set line []
    for {set x $minx} {$x <= $maxx} {incr x} {
        set min_manhattan [expr $maxx + $maxy]
        set min_coords []
        for {set c 0} {$c < [llength $coords]} {incr c} {
            set coord [lindex $coords $c]
            set cx [lindex $coord 0]
            set cy [lindex $coord 1]
            set curr_manhattan [manhattan $cx $cy $x $y]

            if {$curr_manhattan < $min_manhattan} {
                set min_coords [list $c]
                set min_manhattan $curr_manhattan
            } elseif {$curr_manhattan == $min_manhattan} {
                lappend min_coords $c
            }
        }
        if {[llength $min_coords] == 1} {
            lappend line [lindex $min_coords 0]
        } else {
            lappend line .
        }
    }
    lappend grid $line
}

# Print the grid (used for debug)
proc print {grid} {
    foreach line $grid {
        puts [join $line ""]
    }
}

# Find out the infinites and count all numbers in the grid
for {set y 0} {$y <= [expr $maxy - $miny]} {incr y} {
    for {set x 0} {$x <= [expr $maxx - $minx]} {incr x} {
        set num [lindex [lindex $grid $y] $x]
        if {$x == 0 || $y == 0 ||
            $x == [expr $maxx - $minx] || $y == [expr $maxy - $miny]} {
            if {$num != "."} {
                lappend infinite $num
            }
        }

        incr count($num)
    }
}
set infinite [lsort -unique $infinite]

# Find out the maximum amout of one number, which is not infinite
set max 0
foreach {key value} [array get count] {
    if {[lsearch $infinite $key] >= 0} {
        continue
    }
    if {$value > $max} {
        set max $value
    }
}

puts "Largest non-infinite area: $max"


# Create another grid
# Put in # for where the total manhattan distance is less than 10000
for {set y $miny} {$y <= $maxy} {incr y} {
    set line []
    for {set x $minx} {$x <= $maxx} {incr x} {
        set tot_manhattan 0
        for {set c 0} {$c < [llength $coords]} {incr c} {
            set coord [lindex $coords $c]
            set cx [lindex $coord 0]
            set cy [lindex $coord 1]
            set curr_manhattan [manhattan $cx $cy $x $y]

            set tot_manhattan [expr $tot_manhattan + $curr_manhattan]
        }
        if {$tot_manhattan < 10000} {
            lappend line #
        } else {
            lappend line .
        }
    }
    lappend grid2 $line
}

# Count the area
foreach line $grid2 {
    foreach char $line {
        if {$char == "#"} {
            incr area
        }
    }
}

puts "Area total manhattan < 10000: $area"
