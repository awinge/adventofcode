#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	#lappend indata [regexp -inline -all -- {\S+} $row]
	lappend indata $row
    }
}

# Create a associative array index with "x,y" for all points in the height map
set x 0
set y 0
foreach data $indata {
    foreach spot [split $data ""] {
        set map($x,$y) $spot
        incr x
    }
    set x 0
    incr y
}

# Proc for getting all the low points in the map
# Returned as a list of {x y}
proc get_low_points {map_name} {
    upvar 1 $map_name map

    set x 0
    set y 0
    while {[info exists map(0,$y)]} {
        while {[info exists map($x,0)]} {
            set current_hight $map($x,$y)

            set low_point 1

            # left
            if {[info exists map([expr $x - 1],$y)] && $current_hight >= $map([expr $x - 1],$y)} {
                set low_point 0
            }

            # right
            if {[info exists map([expr $x + 1],$y)] && $current_hight >= $map([expr $x + 1],$y)} {
                set low_point 0
            }

            # up
            if {[info exists map($x,[expr $y - 1])] && $current_hight >= $map($x,[expr $y - 1])} {
                set low_point 0
            }

            # down
            if {[info exists map($x,[expr $y + 1])] && $current_hight >= $map($x,[expr $y + 1])} {
                set low_point 0
            }

            if {$low_point} {
                lappend points [list $x $y]
            }

            incr x
        }
        set x 0
        incr y
    }
    return $points
}

# Proc for calculating the sum of all risk level
proc risk_sum {low_points map_name} {
    upvar 1 $map_name map

    foreach point $low_points {
        lassign $point x y
        incr risk $map($x,$y)
        incr risk 1
    }

    return $risk
}

set low_points [get_low_points map]

puts "Sum of all risk level: [risk_sum $low_points map]"

# Recursive function to calculate the basin size
# Sets the visited map when a point has been counted
proc get_basin_size {x y map_name visited_name} {
    upvar 1 $map_name     map
    upvar 1 $visited_name visited

    # Check if the point has already been counted/visited
    # Check if the point exists in the map
    # Check if the point is of height 9 (not part of the basin)
    if {[info exists visited($x,$y)] || ![info exists map($x,$y)] || $map($x,$y) == 9} {
        return 0
    }

    set visited($x,$y) 1

    set return_value 1
    incr return_value [get_basin_size [expr $x - 1] $y $map_name $visited_name]
    incr return_value [get_basin_size [expr $x + 1] $y $map_name $visited_name]
    incr return_value [get_basin_size $x [expr $y - 1] $map_name $visited_name]
    incr return_value [get_basin_size $x [expr $y + 1] $map_name $visited_name]

    return $return_value
}

# If a basin has more than one low point, the second point we are trying to get
# the basin size for will return zero (already in the visited map)
foreach point $low_points {
    lassign $point x y
    lappend sizes [get_basin_size $x $y map visited]
}

# Sort the sizes
set sizes [lsort -dec -integer $sizes]

# Multiply the three larges together
puts "Product of three largest basins: [expr [join [lrange $sizes 0 2] *]]"
