#!/usr/bin/tclsh

set min 231832
set max 767346


#set min 123466
#set max 123466

set first_index  0
set second_index 1
set third_index  2
set fourth_index 3
set fifth_index  4
set sixth_index  5

set first_start [lindex $min $first_index]
set first_stop  [lindex $max $first_index]


proc increasing {num} {
    foreach digit [split $num ""] {
        if {![info exists last]} {
            set last $digit
        } else {
            if {$digit >= $last} {
                set last $digit
            } else {
                return 0
            }
        }
    }
    return 1
}

proc double {num} {
    foreach digit [split $num ""] {
        if {![info exists last]} {
            set last $digit
        } else {
            if {$digit == $last} {
                return 1
            } else {
                set last $digit
            }
        }
    }
    return 0
}

proc extended_double {num} {
    foreach digit [split $num ""] {
        if {![info exists last]} {
            set last $digit
            set adjacent 1
        } else {
            if {$digit == $last} {
                incr adjacent
            } else {
                set last $digit
                if {$adjacent == 2} {
                    return 1
                } else {
                    set adjacent 1
                }
            }
        }
    }
    
    if {$adjacent == 2} {
        return 1
    } else {
        return 0
    }
}

set matching 0

for {set num $min} {$num <= $max} {incr num} {
    if {![increasing $num]} {
        continue
    }

    if {![double $num]} {
        continue
    }
    
    incr matching
}    

puts "Number of matching passwords: $matching"


set matching 0

for {set num $min} {$num <= $max} {incr num} {
    if {![increasing $num]} {
        continue
    }

    if {![extended_double $num]} {
        continue
    }
    incr matching
}    

puts "Number of matching passwords: $matching"
