#!/usr/bin/tclsh

proc count_valid {triangles} {
    set count 0
    foreach triangle $triangles {
	set values [split [regexp -inline -all -- {\S+} $triangle]]
	set a [lindex $values 0]
	set b [lindex $values 1]
	set c [lindex $values 2]
	if {[expr $a + $b] > $c &&
	    [expr $a + $c] > $b &&
	    [expr $b + $c] > $a} {
	    incr count
	}
    }
    return $count
}
set fp [open "input" r]
set fd [read $fp]
close $fp

puts "Valid triangles: [count_valid [split $fd "\n"]]"

for {set i 0} {$i < 3} {incr i} {
    set c 0
    foreach row [split $fd "\n"] {
	set triangle [lappend triangle [lindex $row $i]]
	if {[expr $c % 3] == 2} {
	    set triangles [lappend triangles $triangle]
	    unset triangle
	}
	incr c
    }
}

puts "Valid column triangles: [count_valid $triangles]"
