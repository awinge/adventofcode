#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	#lappend indata [regexp -inline -all -- {\S+} $row]
	lappend indata "$row"
    }
}

foreach row $indata {
    set parse {}
    set match {}
    set syntax_error_score 0

    foreach c [split $row ""] {
        set match [lindex $parse end]


        # If an opening bracket, add it to the parse list and continue
        # with next bracket
        # If a closing bracket, check if it matches last parsed opening bracket
        # otherwise give a score
        switch $c {
            "(" -
            "\[" -
            "\{" -
            "<" {
                lappend parse $c
                continue
            }
            ")" {
                if {$match != "("} {
                    set syntax_error_score 3
                }
            }
            "\]" {
                if {$match != "\["} {
                    set syntax_error_score 57
                }
            }
            "\}" {
                if {$match != "\{"} {
                    set syntax_error_score 1197
                }
            }
            ">" {
                if {$match != "<"} {
                    set syntax_error_score 25137
                }
            }
        }

        # Removed the matched character
        set parse [lreplace $parse end end]

        # If we got a score, accumulate total score and do next row
        if {$syntax_error_score != 0} {
            incr total_syntax_error_score $syntax_error_score
            break
        }
    }

    # No syntax error, calculate the autocomplete score
    if {$syntax_error_score == 0} {
        set autocomplete_score 0

        # Go through the parse list backwards to calculate
        # the autocomplete score
        foreach c [lreverse $parse] {
            switch $c {
                "(" {
                    set point 1
                }
                "\[" {
                    set point 2
                }
                "\{" {
                    set point 3
                }
                "<" {
                    set point 4
                }
            }

            set autocomplete_score [expr 5 * $autocomplete_score + $point]
        }

        # Add score to a list of scores
        lappend autocomplete_scores $autocomplete_score
    }
}

puts "Total syntax error score: $total_syntax_error_score"

set autocomplete_scores [lsort -integer $autocomplete_scores]
set middle_autocomplete_score [lindex $autocomplete_scores [expr [llength $autocomplete_scores] / 2]]

puts "Middle autocomplete score: $middle_autocomplete_score"
