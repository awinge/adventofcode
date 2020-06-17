#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Create map
set x 0
set y 0
foreach row [split $fd "\n"] {
    if {$row != ""} {
        foreach pos [split $row ""] {
            set map($x,$y) $pos
            incr x
        }
        set x 0
        incr y
    }
}

# Get max x and y
foreach {coord square} [array get map] {
    lassign [split $coord ","] x y
    if {![info exists max_x] || $x > $max_x} {
        set max_x $x
    }
    
    if {![info exists max_y] || $y > $max_y} {
        set max_y $y
    }
}

# Printing map
proc print {} {
    upvar 1 map map
    
    set x 0
    set y 0

    while 1 {
        if {[info exists map($x,$y)]} {
            puts -nonewline $map($x,$y)
            incr x
        } else {
            if {$x == 0} {
                # Map ended
                break
            } else {
                # Row ended
                set x 0
                puts ""
                incr y
            }
        }
    }
}

# Help function to multiply each item in a list of lists with a list of factors
proc multiply {angles factors} {
    return [lmap angle $angles {lmap part $angle factor $factors {expr {$part * $factor}}}]
}

# Get
proc get_angle_list {max_x max_y} {
    set angles []

    for {set x 1} {$x <= $max_x} {incr x} {
        for {set y 1} {$y <= $max_y} {incr y} {
            set valid 1
            foreach angle $angles {
                lassign $angle ang_x ang_y

                # Check for even division for x and y and the same factor on x as y
                if {[expr $x % $ang_x] == 0 && [expr $y % $ang_y] == 0 &&
                    [expr $x / $ang_x] == [expr $y / $ang_y]} {
                    set valid 0
                }
            }
            if {$valid == 1} {
                lappend angles [list $x $y]
            }
        }
    }

    set quad1 [multiply $angles {1 -1}]
    set quad2 [multiply $angles {1 1}]
    set quad3 [multiply $angles {-1 1}]
    set quad4 [multiply $angles {-1 -1}]
    set lines {{1 0} {0 1} {-1 0} {0 -1}}
    return [list {*}$quad1 {*}$quad2 {*}$quad3 {*}$quad4 {*}$lines]
}

# Calculate astroids in sight for coordinates
proc calc {x y angles} {
    upvar 1 map map

    set astroids 0
    foreach angle $angles {
        lassign $angle ang_x ang_y

        set multiplier 1
        while 1 {
            set check_x [expr $x + ($ang_x * $multiplier)]
            set check_y [expr $y + ($ang_y * $multiplier)]

            if {![info exists map($check_x,$check_y)]} {
                break
            } else {
                if {$map($check_x,$check_y) != "."} {
                    incr astroids
                    break
                } else {
                    incr multiplier
                }
            }
        }
    }
    return $astroids
}

set angles_list [get_angle_list $max_x $max_y]

foreach {coord content} [array get map] {
    if {$content == "#"} {
        lassign [split $coord ","] x y
        set map($coord) [calc $x $y $angles_list]
    }
}

foreach {coord content} [array get map] {
    if {$content != "."} {
        if {![info exists max_asteroids] || $content > $max_asteroids} {
            set max_asteroids $content
            lassign [split $coord ","] x_max_asteroids y_max_asteroids
        }
    }
}

puts "Max asteroids: $max_asteroids"

# Part 2

# Get radian angle starting from straight up as zero
proc get_rad_angle {x y} {
    if {$x < 0 && $y < 0} {
        return [expr atan2($y, $x) + 2.5*atan2(0,-1)]
    } else {
        return [expr atan2($y, $x) + atan2(1,0)]
    }
}

# Compare function to be able to sort angle_list
proc compare {a b} {
    set angle_a [get_rad_angle {*}$a]
    set angle_b [get_rad_angle {*}$b]

    if {$angle_a < $angle_b} {
        return -1
    } else {
        return 1
    }
}

set angles_list [lsort -command compare $angles_list]

# Vaporize asteroids until number has been reached
# No check if no asteroids left
proc vaporize {x y angles number} {
    upvar 1 map map

    set vaporized 0
    while 1 {
        foreach angle $angles {
            lassign $angle ang_x ang_y

            set multiplier 1
            while 1 {
                set check_x [expr $x + ($ang_x * $multiplier)]
                set check_y [expr $y + ($ang_y * $multiplier)]
                
                if {![info exists map($check_x,$check_y)]} {
                    break
                } else {
                    if {$map($check_x,$check_y) != "."} {
                        set map($check_x,$check_y) .
                        incr vaporized
                        if {$vaporized == $number} {
                            return [list $check_x $check_y]
                        }
                        break
                    } else {
                        incr multiplier
                    }
                }
            }
        }
    }
}

lassign [vaporize $x_max_asteroids $y_max_asteroids $angles_list 200] x y

puts "200th vaporized asteroid: ($x,$y)"
puts "Answer: [expr 100*$x + $y]"
