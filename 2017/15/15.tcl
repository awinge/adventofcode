#!/usr/bin/tclsh

set gena 722
set genb 354

proc next_a {a} {
    return [expr ($a * 16807) % 2147483647]
}

proc next_b {b} {
    return [expr ($b * 48271) % 2147483647]
}

set tot 0
for {set i 0} {$i < 40000000} {incr i} {
    set gena [next_a $gena]
    set genb [next_b $genb]
    if {[expr ($gena & 0xFFFF) == ($genb & 0xFFFF)]} {
	incr tot
    }
}
puts "Matching first part: $tot"


set gena 722
set genb 354

set tot 0
for {set i 0} {$i <= 5000000} {incr i} {
    set gena [next_a $gena]
    set genb [next_b $genb]
    while {[expr $gena % 4] != 0} {
	set gena [next_a $gena]
    }
    while {[expr $genb % 8] != 0} {
	set genb [next_b $genb]
    }

    if {[expr ($gena & 0xFFFF) == ($genb & 0xFFFF)]} {
	incr tot
    }
}
puts "Matching second part: $tot"

