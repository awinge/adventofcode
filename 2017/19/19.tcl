#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	set indata [lappend indata $row]
    }
}

foreach data $indata {
    set charnum 0
    foreach char [split $data ""] {
        if {![info exists maze]} {
            set maze [list]
        }

        if {$charnum > [expr [llength $maze] - 1]} {
            lappend maze [list $char]
        } else {
            set column [lindex $maze $charnum]
            lappend column $char
            set maze   [lreplace $maze $charnum $charnum $column]
        }
        incr charnum
    }
}

proc find_start maze {
    set y 0
    for {set x 0} {$x < [llength $maze]} {incr x} {
        if {[lindex [lindex $maze $x] $y] == "|"} {
            return [list $x $y]
        }
    }
}

proc next_cord {x_var y_var dir} {
    upvar 1 $x_var x
    upvar 1 $y_var y

    switch $dir {
        up    { set y [expr $y - 1] }
        down  { set y [expr $y + 1] }
        left  { set x [expr $x - 1] }
        right { set x [expr $x + 1] }
    }
}

proc is_path {maze x y} {
    set char [lindex [lindex $maze $x] $y]
    if {$char != " "} {
        return 1
    } else {
        return 0
    }
}

proc get_new_dir {maze x y dir_var} {
    upvar 1 $dir_var dir

    switch $dir {
        up -
        down {
            if {[is_path $maze [expr $x + 1] $y]} {
                set dir "right"
            }
            if {[is_path $maze [expr $x - 1] $y]} {
                set dir "left"
            }
        }
        left -
        right {
            if {[is_path $maze $x [expr $y + 1]]} {
                set dir "down"
            }
            if {[is_path $maze $x [expr $y - 1]]} {
                set dir "up"
            }
        }
    }
}
    
proc traverse_maze {maze x y dir} {
    set steps 0
    while 1 {
        set char [lindex [lindex $maze $x] $y]
        switch -regexp -matchvar match -- $char {
            [A-Z] {
                puts -nonewline $match 
                next_cord x y $dir
            }
            [|-] {
                next_cord x y $dir
            }
            [+] {
                get_new_dir $maze $x $y dir
                next_cord x y $dir
            }
            default {
                puts ""
                puts "Reached end after $steps steps"
                break
            }
        }
        incr steps
    }
}
        
set start [find_start $maze]
set x [lindex $start 0]
set y [lindex $start 1]

traverse_maze $maze $x $y down

