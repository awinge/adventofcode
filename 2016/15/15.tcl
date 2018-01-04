#!/usr/bin/tclsh

set discs {{15 17} {2 3} {4 19} {2 13} {2 7} {0 5}}
set discs2 [concat $discs {{0 11}}]

proc force_discs {discs} {
    set increment 1
    set offset 0
    set discpos_offset 0
    foreach disc $discs {
        incr discpos_offset
        set pos [lindex $disc 0]
        set mod [lindex $disc 1]
        while {[expr ($pos + $discpos_offset + $offset) % $mod] != 0} {
            set offset [expr $offset + $increment]
        }
        set increment [expr $increment * $mod]
    }
    return $offset
}

puts "Time to press button: [force_discs $discs]"
puts "Time to press button with additional disc: [force_discs $discs2]"
