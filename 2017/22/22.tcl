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
    for {set c 0} {$c < [string length $data]} {incr c} {
        if {![info exists orig_grid] || $c >= [llength $orig_grid]} {
            lappend orig_grid [string index $data $c]
        } else {
            set column [lindex $orig_grid $c]
            set column [concat $column [string index $data $c]]
            lset orig_grid $c $column
        }
        
    }        
}

proc turn_left {dir} {
    switch $dir {
        N { return W }
        W { return S }
        S { return E }
        E { return N }
    }
}

proc turn_right {dir} {
    switch $dir {
        N { return E }
        E { return S }
        S { return W }
        W { return N }
    }
}

proc turn_back {dir} {
    switch $dir {
        N { return S }
        S { return N }
        W { return E }
        E { return W }
    }
}

proc is_infected {grid x y} {
    if {[lindex $grid $x $y] == "#"} {
        return 1
    } else {
        return 0
    }
}

proc get_state {grid x y} {
    return [lindex $grid $x $y]
}

proc switch_state {grid x y} {
    global infections
    set d [lindex $grid $x $y]
    if {$d == "#"} {
        lset grid $x $y .
    } else {
        lset grid $x $y #
        incr infections
    }
    return $grid
}

proc change_state {grid x y} {
    global infections
    set d [lindex $grid $x $y]
    switch $d {
        .  {lset grid $x $y W}
        W  {lset grid $x $y #; incr infections}
        \# {lset grid $x $y F}
        F  {lset grid $x $y .}
    }            
    return $grid
}

proc move {x y dir} {
    switch $dir {
        N { set y [expr $y - 1] }
        S { set y [expr $y + 1] }
        W { set x [expr $x - 1] }
        E { set x [expr $x + 1] }
    }
    return [list $x $y]
}

proc add_column_before {grid} {
    for {set y 0} {$y < [llength [lindex $grid 0]]} {incr y} {
        lappend new_column .
    }
    set grid [linsert $grid 0 $new_column]
    return $grid
}

proc add_column_after {grid} {
    for {set y 0} {$y < [llength [lindex $grid 0]]} {incr y} {
        lappend new_column .
    }
    lappend grid $new_column
    return $grid
}

proc add_row_before {grid} {
    for {set x 0} {$x < [llength $grid]} {incr x} {
        set column [lindex $grid $x]
        set column [linsert $column 0 .]
        lset grid $x $column
    }
    return $grid
}

proc add_row_after {grid} {
    for {set x 0} {$x < [llength $grid]} {incr x} {
        set column [lindex $grid $x]
        lappend column .
        lset grid $x $column
    }
    return $grid
}

proc print_grid {grid} {
    for {set y 0} {$y < [llength [lindex $grid 0]]} {incr y} {
        for {set x 0} {$x < [llength $grid]} {incr x} {
            puts -nonewline [lindex $grid $x $y]
        }
        puts ""
    }
}

proc do_one_step {gridvar xvar yvar dirvar} {
    upvar 1 $gridvar grid
    upvar 1 $xvar x
    upvar 1 $yvar y
    upvar 1 $dirvar dir

    if {[is_infected $grid $x $y]} {
        set dir [turn_right $dir]
    } else {
        set dir [turn_left $dir]
    }

    set grid [switch_state $grid $x $y]

    set move_return [move $x $y $dir]

    set x [lindex $move_return 0]
    set y [lindex $move_return 1]

    if {$x < 0} {
        set grid [add_column_before $grid]
        set x 0
    }

    if {$x >= [llength $grid]} {
        set grid [add_column_after $grid]
    }

    if {$y < 0} {
        set grid [add_row_before $grid]
        set y 0
    }

    if {$y >= [llength [lindex $grid 0]]} {
        set grid [add_row_after $grid]
    }
}

proc do_two_step {gridvar xvar yvar dirvar} {
    upvar 1 $gridvar grid
    upvar 1 $xvar x
    upvar 1 $yvar y
    upvar 1 $dirvar dir

    switch [get_state $grid $x $y] {
        .  { set dir [turn_left $dir] }
        W  { set dir $dir }
        \# { set dir [turn_right $dir] }
        F  { set dir [turn_back $dir] }
    }

    set grid [change_state $grid $x $y]

    set move_return [move $x $y $dir]

    set x [lindex $move_return 0]
    set y [lindex $move_return 1]

    if {$x < 0} {
        set grid [add_column_before $grid]
        set x 0
    }

    if {$x >= [llength $grid]} {
        set grid [add_column_after $grid]
    }

    if {$y < 0} {
        set grid [add_row_before $grid]
        set y 0
    }

    if {$y >= [llength [lindex $grid 0]]} {
        set grid [add_row_after $grid]
    }
}

set startx [expr [llength $orig_grid] / 2]
set starty [expr [llength [lindex $orig_grid 0]] / 2]

set grid $orig_grid
set x $startx
set y $starty
set dir N
set infections 0


set rounds 10000

for {set i 1} {$i <= $rounds} {incr i} {
    do_one_step grid x y dir
}

puts "Number of nodes that got infected: $infections"


set grid $orig_grid
set x $startx
set y $starty
set dir N
set infections 0

set rounds 10000000

for {set i 1} {$i <= $rounds} {incr i} {
    do_two_step grid x y dir
}

puts "Number of nodes that got infected: $infections"
