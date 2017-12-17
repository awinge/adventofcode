#!/usr/bin/tclsh

set indata 348

set loops 2017
set result [list 0]
set cur_pos 0
set length 1
for {set i 1} {$i <= $loops} {incr i} {
    set cur_pos [expr ($cur_pos + $indata) % $length]
    set result [lreplace $result $cur_pos $cur_pos [lindex $result $cur_pos] $i]
    incr cur_pos
    incr length
}

puts "After last value [lindex $result [expr $cur_pos + 1]]"



set loops 50000000
set cur_pos 0
set length 1
for {set i 1} {$i <= $loops} {incr i} {
    set cur_pos [expr ($cur_pos + $indata) % $length]

    if {$cur_pos == 0} {
        set after_zero $i
    }
    incr cur_pos
    incr length
}

puts "Value after 0 is: $after_zero"

