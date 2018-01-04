#!/usr/bin/tclsh

set input 11101000110010100
set first_length 272
set second_length 35651584


proc mod_dragon {input} {
    set a $input
    set b [string map {0 1 1 0} [string reverse $input]]
    return "${a}0${b}"
}

proc extend_input {input length} {
    while {[string length $input] < $length} {
        set input [mod_dragon $input]
    }
    set input [string range $input 0 [expr $length - 1]]
    return $input
}

proc calc_checksum {input} {
    while {[expr [string length $input] % 2] == 0} {
        set index 0
        set new_input ""
        while {$index < [expr [string length $input] - 1]} {
            set pair [string range $input $index [expr $index + 1]]
            switch $pair {
                00 -
                11 {append new_input 1}
                01 -
                10 {append new_input 0}
            }
            set index [expr $index + 2]
        }
        set input $new_input
    }
    return $input
}

set first_input [extend_input $input $first_length]
set second_input [extend_input $input $second_length]

puts "First checksum: [calc_checksum $first_input]"
puts "Second checksum: [calc_checksum $second_input]"

