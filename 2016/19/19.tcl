#!/usr/bin/tclsh

set input 3012210
set testinput 5

proc find_next_non_empty {elves index} {
    for {set i 1} {$i < [llength $elves]} {incr i} {
        set next [expr ($index + $i) % [llength $elves]]
        if {[lindex $elves $next]} {
            return $next
        }
    }
    return -1
}

proc find_across {elves index} {
    return [expr ($index + ([llength $elves] / 2)) % [llength $elves]]
}

for {set i 0} {$i < $input} {incr i} {
    lappend elves 1
}
set turn 0

while {1} {
    set steal_from [find_next_non_empty $elves $turn]
    lset elves $steal_from 0

    set next_turn [find_next_non_empty $elves $turn]
    if {$next_turn == -1} {
        break
    }
    set turn $next_turn
}

puts "Lucky elf: [expr $turn + 1]"



unset elves
for {set i 0} {$i < $input} {incr i} {
    lappend elves [expr $i + 1]
}
set turn 0

while {1} {
    set steal_from [find_across $elves $turn]
    set elves [lreplace $elves[set elves {}] $steal_from $steal_from]

    set length [llength $elves]
    if {$turn >= $steal_from} {
        set next_turn [expr $turn % $length]
    } else {
        set next_turn [expr ($turn + 1) % $length]
    }
    if {$length == 1} {
        break
    }
    set turn $next_turn
}

puts "Lucky elf: [lindex $elves 0]"
