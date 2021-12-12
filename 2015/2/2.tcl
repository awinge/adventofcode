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

# Proc to get the amount of paper and ribbon
proc wrap {x y z} {
    # Get the two smallest sides
    lassign [lsort -integer -incr [list $x $y $z]] sx sy

    set paper [expr (2 * $x * $y) + (2 * $x * $z) + (2 * $y * $z) + ($sx * $sy)]
    set ribbon [expr (2 * $sx) + (2 * $sy) + ($x * $y * $z)]

    return [list $paper $ribbon]
}

# Wrap each present and accumulate the total amount
foreach data $indata {
    lassign [split $data "x"] x y z
    lassign [wrap $x $y $z] paper ribbon

    incr total_paper $paper
    incr total_ribbon $ribbon
}

puts "Total square feet of paper: $total_paper"
puts "Total length of ribbon: $total_ribbon"
