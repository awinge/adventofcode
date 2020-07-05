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

# Read in the map
set x 0
set y 0
foreach line $indata {
    foreach char [split $line ""] {
        set map($x,$y) $char
        incr x
        if {[regexp {[a-z]} $char]} {
            incr wanted_keys
        }
    }
    set x 0
    incr y
}

# Get boundaries of map
proc get_boundaries {} {
    upvar 1 map map

    foreach {key value} [array get map] {
        lassign [split $key ","] x y

        if {![info exists min_x] || $x < $min_x} {
            set min_x $x
        }

        if {![info exists max_x] || $x > $max_x} {
            set max_x $x
        }

        if {![info exists min_y] || $y < $min_y} {
            set min_y $y
        }

        if {![info exists max_y] || $y > $max_y} {
            set max_y $y
        }
    }
    return [list $min_x $min_y $max_x $max_y]
}

# Print the map
proc print {boundaries} {
    upvar 1 map map

    lassign $boundaries min_x min_y max_x max_y

    for {set y $min_y} {$y <= $max_y} {incr y} {
        for {set x $min_x} {$x <= $max_x} {incr x} {
            if {[info exists map($x,$y)]} {
                puts -nonewline "$map($x,$y)"
            }
        }
        puts ""
    }
}

# Find coord for a specific character
# If multiple exists the first found coord is returned
proc find_coord {char} {
    upvar 1 map map

    foreach {key value} [array get map] {
        if {$value == $char} {
            return $key
        }
    }
    puts "Could not find $char in map"
    exit
}

# Do a move
proc move {x y direction} {
    switch $direction {
        "north" {
            incr y -1
        }
        "south" {
            incr y 1
        }
        "west" {
            incr x -1
        }
        "east" {
            incr x 1
        }
        default {
            puts "Invalid direction: $direction"
            exit
        }
    }
    return [list $x $y]
}

# Get possible movements from a location
proc get_movements {x y steps} {
    foreach dir {"north" "west" "south" "east"} {
        lassign [move $x $y $dir] new_x new_y
        lappend movements [list $new_x $new_y [expr $steps + 1]]
    }
    return $movements
}

# Traverse the map and create a graph representation
proc build_graph {origin graph_name} {
    upvar 1 map map
    upvar 1 $graph_name graph

    lassign [split [find_coord $origin] ","] x y

    set visited($x,$y) 0
    set unvisited [get_movements $x $y 0]
    set unvisited [lsort -integer -index 2 $unvisited]

    while {[llength $unvisited] != 0} {
        lassign [lindex $unvisited 0] c_x c_y c_steps
        set unvisited [lreplace $unvisited 0 0]

        # Outside the map
        if {![info exists map($c_x,$c_y)]} {
            continue
        }

        # Already visited
        if {[info exists visited($c_x,$c_y)]} {
            continue
        }


        set char $map($c_x,$c_y)
        switch -regexp -- $char {
            [\#] { # Found wall
                continue
            }
            [a-zA-Z] { # Key or Door
                lappend finds $char
                set finds [lsort -unique $finds]
            }
            [\.@0-9] { # Found open space
                set moves [get_movements $c_x $c_y $c_steps]
                set unvisited [list {*}$unvisited {*}$moves]
                set unvisited [lsort -integer -index 2 $unvisited]
            }
        }

        # Never visited or cheaper path found
        if {![info exists visited($c_x,$c_y)] || $c_steps < $visited($c_x,$c_y)} {
            set visited($c_x,$c_y) $c_steps
        }
    }

    if {[info exists finds]} {
        foreach find $finds {
            lassign [split [find_coord $find] ","] f_x f_y
            set f_steps $visited($f_x,$f_y)

            lappend graph($origin) [list $find $f_steps]
        }
    } else {
        set graph($origin) []
    }
}

# Will build a graph by iteration from an origin
proc do_graph {origin graph_name} {
    upvar 1 map map
    upvar 1 $graph_name graph

    build_graph $origin graph
    set new_nodes 1
    while {$new_nodes} {
        set new_nodes 0
        foreach {key value} [array get graph] {
            foreach v $value {
                set node [lindex $v 0]
                if {![info exists graph($node)]} {
                    set new_nodes 1
                    build_graph $node graph
                }
            }
        }
    }
}

# Get possible nodes to reach with the associated cost.
# Bring the set of keys to see which doors can be opened
proc get_nodes {origin keys graph_name} {
    upvar 1 $graph_name graph

    set visited($origin) 0
    set unvisited $graph($origin)
    set unvisited [lsort -integer -index 1 $unvisited]

    while {[llength $unvisited] != 0} {
        lassign [lindex $unvisited 0] current steps
        set unvisited [lreplace $unvisited 0 0]

        # Already visited
        if {[info exists visited($current)]} {
            continue
        }

        set visited($current) $steps

        switch -regexp -- $current {
            [a-z] { # key
                # New key?
                if {[lsearch $keys $current] == -1} {
                    lappend finds $current
                    set finds [lsort -unique $finds]
                } else {
                    set nodes $graph($current)
                    foreach node $nodes {
                        lassign $node n_where n_steps
                        lappend unvisited [list $n_where [expr $n_steps + $steps]]
                        set unvisited [lsort -integer -index 1 $unvisited]
                    }
                }

            }
            [A-Z] { # Key or Door
                if {[lsearch $keys [string tolower $current]] != -1} {
                    set nodes $graph($current)
                    foreach node $nodes {
                        lassign $node n_where n_steps
                        lappend unvisited [list $n_where [expr $n_steps + $steps]]
                        set unvisited [lsort -integer -index 1 $unvisited]
                    }
                }
            }
        }


    }

    if {[info exists finds]} {
        foreach find $finds {
            lappend retnodes [list $find $visited($find)]
        }
        return $retnodes
    } else {
        return []
    }
}

proc traverse_graph {keys location steps wanted_keys} {
    upvar 1 graph graph
    upvar 1 min_steps min_steps
    upvar 1 checked checked

    if {[info exists min_steps] && $min_steps < $steps} {
        return
    }

    if {[llength $keys] == $wanted_keys} {
        if {![info exists min_steps] || $steps < $min_steps} {
            set min_steps $steps
            return
        }
    }

    set k "$location,[lsort $keys]"
    # Check cost for a location with a set of keys
    if {[info exists checked($k)] && $steps >= $checked($k)} {
        return
    } else {
        set checked($k) $steps
    }

    set edges [lsort -integer -index 1 [get_nodes $location $keys graph]]
    foreach edge $edges {
        lassign $edge where cost
        set new_keys $keys
        lappend new_keys $where
        traverse_graph $new_keys $where [expr $steps + $cost] $wanted_keys
    }
}

# Build the graph
do_graph @ graph

# DEBUG PRINTS
#print [get_boundaries]
#foreach {k v} [array get graph] {
#    puts "$k: $v"
#}

# Traverse the graph for finding least number of steps
traverse_graph {} @ 0 $wanted_keys
puts "Minimum number of steps: $min_steps"

proc four_mace {} {
    upvar 1 map map

    lassign [split [find_coord @] ","] x y
    set map([expr $x - 1],[expr $y - 1]) "1"
    set map([expr $x + 1],[expr $y - 1]) "2"
    set map([expr $x - 1],[expr $y + 1]) "3"
    set map([expr $x + 1],[expr $y + 1]) "4"

    set map($x,[expr $y - 1]) "#"
    set map($x,[expr $y + 1]) "#"
    set map([expr $x + 1],$y) "#"
    set map([expr $x - 1],$y) "#"
    set map($x,$y) "#"
}

four_mace
do_graph 1 graph1
do_graph 2 graph2
do_graph 3 graph3
do_graph 4 graph4

# DEBUG PRINTS
#print [get_boundaries]
#puts "graph 1"
#foreach {k v} [array get graph1] {
#    puts "$k: $v"
#}
#
#puts "graph 2"
#foreach {k v} [array get graph2] {
#    puts "$k: $v"
#}
#
#puts "graph 3"
#foreach {k v} [array get graph3] {
#    puts "$k: $v"
#}
#
#puts "graph 4"
#foreach {k v} [array get graph4] {
#    puts "$k: $v"
#}

proc traverse_graphs {keys locations steps wanted_keys} {
    upvar 1 graph1 graph1
    upvar 1 graph2 graph2
    upvar 1 graph3 graph3
    upvar 1 graph4 graph4
    upvar 1 min_steps min_steps
    upvar 1 checked checked

    if {[info exists min_steps] && $min_steps < $steps} {
        return
    }

    if {[llength $keys] == $wanted_keys} {
        if {![info exists min_steps] || $steps < $min_steps} {
            set min_steps $steps
            return
        }
    }

    lassign $locations loc1 loc2 loc3 loc4

    set k "$locations,[lsort $keys]"
    # Check cost for a location with a set of keys
    if {[info exists checked($k)] && $steps >= $checked($k)} {
        return
    } else {
        set checked($k) $steps
    }

    set edges1 [get_nodes $loc1 $keys graph1]
    set edges2 [get_nodes $loc2 $keys graph2]
    set edges3 [get_nodes $loc3 $keys graph3]
    set edges4 [get_nodes $loc4 $keys graph4]
    set edges [lsort -integer -index 1 [list {*}$edges1 {*}$edges2 {*}$edges3 {*}$edges4]]
    foreach edge $edges {
        lassign $edge where cost
        set new_loc1 $loc1
        if {[info exists graph1($where)]} {
            set new_loc1 $where
        }
        set new_loc2 $loc2
        if {[info exists graph2($where)]} {
            set new_loc2 $where
        }
        set new_loc3 $loc3
        if {[info exists graph3($where)]} {
            set new_loc3 $where
        }
        set new_loc4 $loc4
        if {[info exists graph4($where)]} {
            set new_loc4 $where
        }

        set new_keys $keys
        lappend new_keys $where
        traverse_graphs $new_keys [list $new_loc1 $new_loc2 $new_loc3 $new_loc4] [expr $steps + $cost] $wanted_keys
    }
}

if {[info exists min_steps]} {
    unset min_steps
}
if {[info exists checked]} {
    unset checked
}
# Traverse the graphs for finding least number of steps
traverse_graphs {} {1 2 3 4} 0 $wanted_keys
puts "Minimum number of steps: $min_steps"
