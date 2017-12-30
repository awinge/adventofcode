#!/usr/bin/tclsh

set input 1358
set testinput 10
set maze [list]

for {set x 0} {$x < 50} {incr x} {
    set column [list]
    for {set y 0} {$y < 50} {incr y} {
        set value [expr $x * $x + 3 * $x + 2 * $x * $y + $y + $y * $y + $input]
        set value [format %b $value]
        set value [regexp -all {1} $value]
        if {[expr $value % 2] == 1} {
            lappend column #
        } else {
            lappend column .
        }
    }
    lappend maze $column
}

proc print {maze xmax ymax} {
    for {set y 0} {$y < $ymax} {incr y} {
        for {set x 0} {$x < $xmax} {incr x} {
            puts -nonewline [lindex [lindex $maze $x] $y]
        }
        puts ""
    }
}

proc is_wall {maze x y} {
    if { [lindex [lindex $maze $x] $y] != "." } {
        return 1
    } else {
        return 0
    }
}

proc distance {maze x y visited} {
    if {[lsearch $visited [list $x $y]] != -1} {
        return 1000
    }
    if {[is_wall $maze $x $y]} {
        return 1000
    }
    if {$x < 0 || $x >= 50 || $y < 0 || $y >= 50} {
        return 1000
    }
    if {$x == 31 && $y == 39} {
        return 0
    }

    lappend visited [list $x $y]
    return [expr 1 + min([distance $maze [expr $x + 1] $y $visited], [distance $maze $x [expr $y + 1] $visited], [distance $maze [expr $x - 1] $y $visited], [distance $maze $x [expr $y - 1] $visited])]
}

puts "Minimum steps to (31,39): [distance $maze 1 1 {}]"

set tot_visited {}
proc visits {maze x y steps visited} {
    global tot_visited
    
    if {$steps >= 51} {
        set tot_visited [lsort -unique [concat $tot_visited $visited]]
        return
    }
    if {[lsearch $visited [list $x $y]] != -1} {
        set tot_visited [lsort -unique [concat $tot_visited $visited]]
        return
    }
    if {[is_wall $maze $x $y]} {
        set tot_visited [lsort -unique [concat $tot_visited $visited]]
        return
    }
    if {$x < 0 || $y < 0} {
        set tot_visited [lsort -unique [concat $tot_visited $visited]]
        return
    }

    lappend visited [list $x $y]

    visits $maze [expr $x + 1] $y [expr $steps + 1] $visited
    visits $maze $x [expr $y + 1] [expr $steps + 1] $visited
    visits $maze [expr $x - 1] $y [expr $steps + 1] $visited
    visits $maze $x [expr $y - 1] [expr $steps + 1] $visited
}

visits $maze 1 1 0 {}

puts "Reachable coordinates within 50 steps: [llength $tot_visited]"
