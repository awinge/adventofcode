#!/usr/bin/tclsh

proc move_left {tape cursor} {
    if {$cursor == 0} {
        set tape [linsert $tape 0 0]
    } else {
        set cursor [expr $cursor - 1]
    }

    return [list $tape $cursor]
}

proc move_right {tape cursor} {
    if {$cursor == [expr [llength $tape] - 1]} {
        set tape [linsert $tape end 0]
    }
    incr cursor

    return [list $tape $cursor]
}

proc set_value {tape cursor value} {
    set tape [lreplace $tape $cursor $cursor $value]
    return $tape
}

proc do_step {state tape cursor} {
    set value [lindex $tape $cursor]
    switch $state {
        A {
            if {$value == 0} {
                set tape [set_value $tape $cursor 1]
                set move_return [move_right $tape $cursor]
                set state B
            } else {
                set tape [set_value $tape $cursor 0]
                set move_return [move_right $tape $cursor]
                set state C
            }
        }

        B {
            if {$value == 0} {
                set tape [set_value $tape $cursor 0]
                set move_return [move_left $tape $cursor]
                set state A
            } else {
                set tape [set_value $tape $cursor 0]
                set move_return [move_right $tape $cursor]
                set state D
            }

        }

        C {
            if {$value == 0} {
                set tape [set_value $tape $cursor 1]
                set move_return [move_right $tape $cursor]
                set state D
            } else {
                set tape [set_value $tape $cursor 1]
                set move_return [move_right $tape $cursor]
                set state A
            }
        }

        D {
            if {$value == 0} {
                set tape [set_value $tape $cursor 1]
                set move_return [move_left $tape $cursor]
                set state E
            } else {
                set tape [set_value $tape $cursor 0]
                set move_return [move_left $tape $cursor]
                set state D
            }
        }

        E {
            if {$value == 0} {
                set tape [set_value $tape $cursor 1]
                set move_return [move_right $tape $cursor]
                set state F
            } else {
                set tape [set_value $tape $cursor 1]
                set move_return [move_left $tape $cursor]
                set state B
            }
        }

        F {
            if {$value == 0} {
                set tape [set_value $tape $cursor 1]
                set move_return [move_right $tape $cursor]
                set state A
            } else {
                set tape [set_value $tape $cursor 1]
                set move_return [move_right $tape $cursor]
                set state E
            }
        }
    }

    set tape [lindex $move_return 0]
    set cursor [lindex $move_return 1]

    return [list $state $tape $cursor]
}

set steps 12368930
set state A
set tape [list 0]
set cursor 0

for {set i 0} {$i < $steps} {incr i} {
    set step_return [do_step $state $tape $cursor]
    set state  [lindex $step_return 0]
    set tape   [lindex $step_return 1]
    set cursor [lindex $step_return 2]
}

puts "Checksum: [llength [lsearch -all $tape 1]]"
