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

# Create two lists one for inputs and one for outputs
foreach data $indata {

    lassign [split $data "|"] input output

    set input [string trimright $input " "]
    set input [split $input " "]

    set output [string trimleft $output " "]
    set output [split $output " "]

    lappend inputs $input
    lappend outputs $output
}


# Count the number of output with length 2, 3, 4 and 7
set ans 0
foreach output $outputs {
    foreach digit $output {
        set length [string length $digit]
        if {$length == 2 || $length == 3 || $length == 4 || $length == 7} {
            incr ans
        }
    }
}

puts "Occurrences of 1, 4, 7 and 8: $ans"

# Proc that returns all entries from input with length length
proc get_with_length {input length} {
    set output [list]
    foreach i $input {
        if {[string length $i] == $length} {
            lappend output $i
        }
    }
    return $output
}

# Proc that counts how many occurrences of letter in input
proc count {input letter} {
    set c 0
    foreach i $input {
        foreach l [split $i ""] {
            if {$l == $letter} {
                incr c
            }
        }
    }
    return $c
}

# Proc for decoding the input generating a string decoding map
proc decode {input} {
    # First get letter e b and f since they occur a specific number
    # of times when adding over all 0 to 9 digits.
    foreach letter {a b c d e f g} {
        switch [count $input $letter] {
            4 {
                set e $letter
            }
            6 {
                set b $letter
            }
            9 {
                set f $letter
            }
        }
    }

    # Find entry with length 2, 3, 4 and 7
    set l2 [get_with_length $input 2]
    set l3 [get_with_length $input 3]
    set l4 [get_with_length $input 4]
    set l7 [get_with_length $input 7]

    # Get segment a from removing segments in 1 from segments in 7
    set a [string trim $l3 $l2]

    # Get segment c from removing f from 1
    set c [string trim $l2 $f]

    # Get segment d from removing b, c and f from 4
    set d [string map [list $b "" $c "" $f ""] $l4]

    # Get segemnt g from removing a, b, c, d, e, f from 8
    set g [string map [list $a "" $b "" $c "" $d "" $e "" $f ""] $l7]

    # Return the decoder map
    return [list $a a $b b $c c $d d $e e $f f $g g]
}

# Proc to get a number from digit letters
proc get_digit {letters} {
    # Sort the letters in the string first
    set letters [join [lsort [split $letters ""]] ""]

    case $letters {
        abcefg {
            return 0
        }
        cf {
            return 1
        }
        acdeg {
            return 2
        }
        acdfg {
            return 3
        }
        bcdf {
            return 4
        }
        abdfg {
            return 5
        }
        abdefg {
            return 6
        }
        acf {
            return 7
        }
        abcdefg {
            return 8
        }
        abcdfg {
            return 9
        }
    }
    puts "Cound not decode: $letters"
    exit
}

# Adding all the numbers in the input
set ans 0
for {set i 0} {$i < [llength $inputs]} {incr i} {

    # Get the decoder map for the current line
    set decodemap [decode [lindex $inputs $i]]

    # Get the current output
    set output [lindex $outputs $i]

    # Put the number together digit by digit
    set number {}
    foreach digit $output {
        lappend number [get_digit [string map $decodemap $digit]]
        set number [join $number ""]
    }

    # Trim off initial zeros since it is misstaken for octal numbers
    set number [string trimleft $number 0]
    incr ans $number
}

puts "The sum of all numbers: $ans"
