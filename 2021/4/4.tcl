#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	lappend indata [regexp -inline -all -- {\S+} $row]
	#lappend indata $row
    }
}

# Get the draw numbers
set draw [lindex $indata 0]

# The boards are the rest of the data
set indata [lreplace $indata 0 0]

# Proc for checking board win
# Returns 1 if the board has a win, otherwise 0
proc check_board_win {boardname} {
    upvar 1 $boardname board

    # Go through all numbers in rows an columns
    for {set y 0} {$y < 5} {incr y} {
        set row_marks 0
        set col_marks 0
        for {set x 0} {$x < 5} {incr x} {
            lassign $board($x,$y) row_number row_mark
            if {$row_mark} {
                incr row_marks
            }

            lassign $board($y,$x) col_number col_mark
            if {$col_mark} {
                incr col_marks
            }
        }
        if {$row_marks >= 5 || $col_marks >= 5} {
            return 1
        }
    }
    return 0
}

# Calculate the sum of unmarked numbers on a board
proc sum_unmarked {boardname} {
    upvar 1 $boardname board

    for {set y 0} {$y < 5} {incr y} {
        for {set x 0} {$x < 5} {incr x} {
            lassign $board($x,$y) num mark

            if {!$mark} {
                incr sum $num
            }
        }
    }

    return $sum
}

# Create the boards from the input data
#
# Boards are named board0, board1, etc
#
# These are associative arrays indexed with (x,y)
# where x is the column number and y is the row number.
#
# Each entry in the assocative array is a list [number mark]
# number being the actual number in that location and mark if
# that number has been drawn
#
# Also create a locations associative array. It is indexed by
# the number and contains a list of locations for that number.
# The location is a list [board_number x y]. This is used to
# easily mark all board locations containing that number.
#
set board 0
set y 0
foreach row $indata {
    set x 0
    foreach number [split $row] {
        lappend locations($number) [list $board $x $y]

        set board${board}($x,$y) [list $number 0]

        if {$x >= 4} {
            set x 0

            if {$y >= 4} {
                set y 0
                incr board
            } else {
                incr y
            }
        } else {
            incr x
        }
    }
}

set total_boards $board
puts "Number of boards in play: $total_boards"

# Draw numbers one by one
# Use the locations associative array to mark the numbers on boards
# Only mark on a board if it does not have a win
# Draw until all boards has a win
# Keep track of the first and the last win
set num_wins 0
foreach number [split $draw ","] {
    if {[info exists locations($number)]} {

        foreach location $locations($number) {
            lassign $location board x y

            # Mark it if not already won
            if {![info exists board_won($board)]} {
                lset board${board}($x,$y) 1 1
            }
        }

        set board 0
        while {[info exists board${board}]} {
            if {![info exists board_won($board)]} {
                if {[check_board_win board${board}]} {
                    if {$num_wins == 0} {
                        set first_win_number $number
                        set first_win_board $board
                    }
                    set last_win_number $number
                    set last_win_board $board

                    set board_won($board) 1
                    incr num_wins
                }
            }
            incr board
        }
    }
    if {$num_wins >= $total_boards} {
        break
    }
}

set first_sum_unmarked [sum_unmarked board${first_win_board}]
set last_sum_unmarked [sum_unmarked board${last_win_board}]

puts "Final score first win: [expr $first_sum_unmarked * $first_win_number]"
puts "Final score last win: [expr $last_sum_unmarked * $last_win_number]"
