#!/usr/bin/tclsh

set input        157901
set input_length [string length $input]

set recepies(0) 3
set recepies(1) 7
set length      2
set first       0
set second      1

# Produces new recepies
proc new_recepies {f s} {
    global recepies
    global length
    upvar 1 $f first
    upvar 1 $s second

    set first_score $recepies($first)
    set second_score $recepies($second)
    set score_sum [expr $first_score + $second_score]
    foreach char [split $score_sum ""] {
        set recepies($length) $char
        incr length
    }
    set first [expr ($first + $first_score + 1) % $length]
    set second [expr ($second + $second_score + 1) % $length]
}

# Get a range from recepies as a string
proc get_range {first last} {
    global recepies
    global length

    for {set i $first} {$i <= $last} {incr i} {
        if {![info exists recepies($i)]} {
            return ""
        }
        lappend result $recepies($i)
    }

    return [join $result ""]
}

# Looping until first and second part is finished
set found 0
while {$length < [expr $input + 10] || !$found} {
    new_recepies first second

    if {!$found &
        [get_range [expr $length - $input_length] [expr $length - 1]] == $input} {
        set left_of_input [expr $length - $input_length]
        set found 1
    }

    # If two new recepies 
    if {!$found &&
        [get_range [expr $length - $input_length - 1] [expr $length - 2]] == $input} {
        set left_of_input [expr $length - $input_length - 1]
        set found 1
    }
}

puts -nonewline "Ten recepies after $input: "
for {set i 0} {$i < 10} {incr i} {
    puts -nonewline $recepies([expr $input + $i])
}
puts ""

puts "Recepies left of $input: $left_of_input"
