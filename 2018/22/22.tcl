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

foreach data $indata {
    regexp {depth: ([\d]*)} $data _match depth
    regexp {target: ([\d]*),([\d]*)} $data _match targetx targety
}

proc get_geo_index {x y} {
    global targetx targety
    global geo
    
    if {[info exists geo($x,$y)]} {
        return $geo($x,$y)
    }

    if {$x == 0 && $y == 0} {
        set geo_index 0
    } elseif {$x == $targetx && $y == $targety} {
        set geo_index  0
    } elseif {$y == 0} {
        set geo_index [expr $x * 16807]
    } elseif {$x == 0} {
        set geo_index [expr $y * 48271]
    } else {
        set geo_index [expr [get_erosion_level [expr $x - 1] $y] * [get_erosion_level $x [expr $y - 1]]]
    }

    set geo($x,$y) $geo_index
    return $geo_index
}

proc get_erosion_level {x y} {
    global erosion
    global depth
    
    if {[info exists erosion($x,$y)]} {
        return $erosion($x,$y)
    }
    
    set erosion_level [expr ([get_geo_index $x $y] + $depth) % 20183]
    set erosion($x,$y) $erosion_level
    return $erosion_level
}

proc get_type {x y} {
    global type
    
    if {[info exists type($x,$y)]} {
        return $type($x,$y)
    }

    set region_type [expr [get_erosion_level $x $y] % 3]
    set type($x,$y) $region_type
    return $region_type
}

proc switch_gear {gear type} {
    switch $type {
        0 {
            switch $gear {
                "n" {
                    puts "Error"
                    exit
                }
                "t" { return "c" }
                "c" { return "t" }
                default {
                    puts "Error"
                    exit
                }
            }
        }
        1 {
            switch $gear {
                "n" { return "c" }
                "t" {
                    puts "Error"
                    exit
                }
                "c" { return "n" }
                default {
                    puts "Error"
                    exit
                }
            }
        }
        2 {
            switch $gear {
                "n" { return "t" }
                "t" { return "n" }
                "c" {
                    puts "Error"
                    exit
                }
                default {
                    puts "Error"
                    exit
                }
            }
        }
        default {
            puts "Error"
            exit
        }
    }
}

proc allowed_gear {x y gear} {
    set type [get_type $x $y]

    switch $type {
        0 {
            if {$gear == "t" || $gear == "c"} {
                return 1
            } else {
                return 0
            }
        }
        1 {
            if {$gear == "n" || $gear == "c"} {
                return 1
            } else {
                return 0
            }
        }
        2 {
            if {$gear == "n" || $gear == "t"} {
                return 1
            } else {
                return 0
            }
        }
        default {
            puts "Error"
            exit
        }
    }
}

proc possible {x y gear} {
    if {$x >= 0 && $y >= 0 && [allowed_gear $x $y $gear] == 1} {
        return 1
    } else {
        return 0
    }
}

proc manhattan {x y gear gx gy ggear} {
    return 0
    set dx [expr abs($x - $gx)]
    set dy [expr abs($y - $gy)]
    if {$gear == $ggear} {
        set dgear 0
    } else {
        set dgear 7
    }

    return [expr $dx + $dy + $dgear]
}

proc in_open {x y gear} {
    global open_list
    
    if {[info exists open_list($x,$y,$gear)]} {
        return 1
    } else {
        return 0
    }
}

proc add_to_open {x y gear f g h} {
    global open_list
    global open_start

    if {![info exists open_start]} {
        set open_start [list -1 -1 -1]
    }

    set previous [list -1 -1 -1]
    set current  $open_start
    set new      [list $x $y $gear]
        
    while {$current != [list -1 -1 -1]} {
        lassign $open_list([join $current ,]) values next previous
        lassign $values cf cg ch
        if {$f < $cf} {
            break
        }
        set previous $current
        set current $next
    }
    
    if {$previous == [list -1 -1 -1]} {
        set open_list([join $new ,]) [list [list $f $g $h] $current $previous]
        set open_start $new
    } else {
        set open_list([join $new ,]) [list [list $f $g $h] $current $previous]
        lset open_list([join $previous ,]) 1 $new
    }

    if {$current != [list -1 -1 -1]} {
        lset open_list([join $current ,]) 2 $new
    }
}

proc remove_from_open {x y gear} {
    global open_list
    global open_start

    set current [list $x $y $gear]
    
    lassign $open_list([join $current ,]) _value next previous
    unset open_list([join $current ,])

    if {$open_start == $current} {
        set open_start $next
    }

    if {$previous != [list -1 -1 -1]} {
        lset open_list([join $previous ,]) 1 $next
    }

    if {$next != [list -1 -1 -1]} {
        lset open_list([join $next ,]) 2 $previous
    }
}

proc open_length {} {
    global open_list

    return [array size open_list]
}
    
proc get_first_open {} {
    global open_list
    global open_start

    lassign $open_list([join $open_start ,]) values
    return [list {*}$open_start {*}$values]
}

proc get_values_open {x y gear} {
    global open_list

    set current [list $x $y $gear]
    return [lindex $open_list([join $current ,]) 0]
}

proc analyze {sx sy sgear gx gy ggear} {
    add_to_open $sx $sy $sgear 0 0 [manhattan $sx $sy $sgear $gx $gy $ggear]

    set finished 0
    while {[open_length] > 0} {
        # Get the top item
        lassign [get_first_open] x y gear f g h

        if {[info exists closed($gx,$gy,$ggear)]} {
            lassign $closed($gx,$gy,$ggear) gg gf gh
            if {$gf < $f} {
                remove_from_open $x $y $gear
                continue
            }
        }
        
        if {$x == $gx && $y == $gy && $gear == $ggear} {
            set finished 1
        } else {
            foreach dir [list u d r l g] {
                switch $dir {
                    u {
                        set nx    $x
                        set ny    [expr $y - 1]
                        set ngear $gear
                    }
                    d {
                        set nx    $x
                        set ny    [expr $y + 1]
                        set ngear $gear
                    }
                    r {
                        set nx    [expr $x + 1]
                        set ny    $y
                        set ngear $gear
                    }
                    l {
                        set nx    [expr $x - 1]
                        set ny    $y
                        set ngear $gear
                    }
                    g {
                        set nx    $x
                        set ny    $y
                        set ngear [switch_gear $gear [get_type $x $y]]
                    }
                    default {
                        puts "error"
                        exit
                    }
                }
                if {[possible $nx $ny $ngear] == 1} {
                    if {$ngear != $gear} {
                        set ng [expr $g + 7]
                    } else {
                        set ng [expr $g + 1]
                    }
                    set nh [manhattan $nx $ny $ngear $gx $gy $ggear]
                    set nf [expr $ng + $nh]

                    if {[info exists closed($nx,$ny,$ngear)]} {
                        lassign $closed($nx,$ny,$ngear) cf

                        if {$nf < $cf} {
                            add_to_open $nx $ny $ngear $nf $ng $nh
                            unset closed($nx,$ny,$ngear)
                        }
                    } else {
                        if {[in_open $nx $ny $ngear]} {
                            lassign [get_values_open $nx $ny $ngear] of
                            
                            if {$nf < $of} {
                                remove_from_open $nx $ny $ngear
                                add_to_open $nx $ny $ngear $nf $ng $nh
                            }
                        } else {
                            add_to_open $nx $ny $ngear $nf $ng $nh
                        }
                    }
                }
            }
        }
        set closed($x,$y,$gear) [list $f $g $h]
        remove_from_open $x $y $gear
    }
    return $closed($gx,$gy,$ggear)
}

for {set x 0} {$x <= $targetx} {incr x} {
    for {set y 0} {$y <= $targety} {incr y} {
        incr sum [get_type $x $y]
    }
}
puts "Risk level: $sum"

puts "(Long execution time)"
set goal_node [analyze 0 0 "t" $targetx $targety "t"]
puts "Minutes to reach target: [lindex $goal_node 1]"




