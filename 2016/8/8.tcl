#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	set indata [lappend indata [regexp -inline -all -- {\S+} $row]]
    }
}

set xsize 50
set ysize 6

proc set_rect {xsize ysize val} {
    global display
    for {set x 0} {$x < $xsize} {incr x} {
	for {set y 0} {$y < $ysize} {incr y} {
	    set display($x,$y) $val
	}
    }
}

proc rotate_column {c value} {
    global display
    global ysize
    set value [expr $value % $ysize]
    for {set y 0} {$y < $ysize} {incr y} {
	set orig_column($y) $display($c,$y)
    }
    for {set y 0} {$y < $ysize} {incr y} {
	set display($c,[expr ($y + $value) % $ysize]) $orig_column($y)
    }
}

proc rotate_row {r value} {
    global display
    global xsize
    set value [expr $value % $xsize]
    for {set x 0} {$x < $xsize} {incr x} {
	set orig_row($x) $display($x,$r)
    }
    for {set x 0} {$x < $xsize} {incr x} {
	set display([expr ($x + $value) % $xsize],$r) $orig_row($x)
    }
}

proc print_display {} {
    global xsize
    global ysize
    global display
    for {set y 0} {$y < $ysize} {incr y} {
	for {set x 0} {$x < $xsize} {incr x} {
	    if {$display($x,$y)} {
		puts -nonewline "*"
	    } else {
		puts -nonewline " "
	    }
	}
	puts ""
    }
}
    
proc count_pixels {} {
    global xsize
    global ysize
    global display
    set count 0
    for {set y 0} {$y < $ysize} {incr y} {
	for {set x 0} {$x < $xsize} {incr x} { 
	    if {$display($x,$y)} {
		incr count
	    }
	}
    }
    return $count
}

   
set_rect $xsize $ysize 0

foreach data $indata {
    set instr [split $data " "]
    set command [lindex $instr 0]

    switch $command {
	rect {
	    set dimension [split [lindex $instr 1] "x"]
	    set cx [lindex $dimension 0]
	    set cy [lindex $dimension 1]
	    set_rect $cx $cy 1
	}
	rotate {
	    set direction [lindex $instr 1]
	    set value [lindex $instr 4]
	    switch $direction {
		column {
		    set rx [lindex [split [lindex $instr 2] "="] 1]
		    rotate_column $rx $value
		}
		row {
		    set ry [lindex [split [lindex $instr 2] "="] 1]
		    rotate_row $ry $value
		}
	    }
	}
    }
}

puts "Number of pixels: [count_pixels]"
puts ""
print_display
