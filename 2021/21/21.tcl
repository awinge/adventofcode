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

foreach data $indata {
    if {[regexp {Player ([0-9]*) starting position: ([0-9]*)} $data match player pos]} {
        set p${player}_start $pos
        continue
    }

    puts "Unparsed data: $data"
    exit
}

set p1 $p1_start
set p2 $p2_start
set p1_score 0
set p2_score 0

# Proc for rolling the die. Initiate it to 100 so first roll will be 1
set die 100
proc roll {} {
    global die
    global rolls

    incr rolls
    incr die
    if {$die > 100} {
        set die 1
    }
    return $die
}

# Run the game, P1 goes first, until one player reaches 1000 points
set turn p1
while {$p1_score < 1000 && $p2_score < 1000} {
    # Roll the die three times, do mod 10 since the board only has 10
    # spaces
    set roll [expr [roll] + [roll] + [roll]]
    set roll [expr $roll % 10]

    # Incr the player with the roll. Handle going from space 10 to 1
    incr $turn $roll
    if {[set $turn] > 10} {
        incr $turn -10
    }

    # Increment the score
    incr ${turn}_score [set $turn]

    # Switch turns
    if {$turn == "p1"} {
        set turn p2
    } else {
        set turn p1
    }
}

# Get the loser score
if {$p1_score > $p2_score} {
    set loser_score $p2_score
} else {
    set loser_score $p1_score
}

puts "Losing score * number of rolls: [expr $loser_score * $rolls]"

# Proc for running a game with quantum die
#
# Inputs:
#  - p1 position
#  - p2 position
#  - p1 score
#  - p2 score
#  - Whos turn it is
#
# Outputs (as a list):
#   - Number of p1 wins
#   - Number of p2 wins
proc game {p1 p2 p1_score p2_score turn} {
    global memo

    # Check if the result is already known for this combination
    if {[info exist memo($p1,$p2,$p1_score,$p2_score,$turn)]} {
        return $memo($p1,$p2,$p1_score,$p2_score,$turn)
    }

    # p1 wins
    if {$p1_score >= 21} {
        return [list 1 0]
    }

    # p2 wins
    if {$p2_score >= 21} {
        return [list 0 1]
    }

    # For all possible die combinations (3 rolls)
    for {set i 1} {$i <= 3} {incr i} {
        for {set j 1} {$j <= 3} {incr j} {
            for {set k 1} {$k <=3} {incr k} {

                # Max roll is 9, no mod 10 needed
                set roll [expr $i + $j + $k]

                if {$turn == "p1"} {
                    # p1's new position for this roll
                    set new_p1 [expr $p1 + $roll]
                    if {$new_p1 > 10} {
                        incr new_p1 -10
                    }

                    # Run the game for that roll (and new score)
                    lassign [game $new_p1 $p2 [expr $p1_score + $new_p1] $p2_score p2] p1_wins p2_wins

                    # Add the result to memo
                    set memo($new_p1,$p2,[expr $p1_score + $new_p1],$p2_score,p2) [list $p1_wins $p2_wins]
                } else {
                    set new_p2 [expr $p2 + $roll]
                    if {$new_p2 > 10} {
                        incr new_p2 -10
                    }
                    lassign [game $p1 $new_p2 $p1_score [expr $p2_score + $new_p2] p1] p1_wins p2_wins
                    set memo($p1,$new_p2,$p1_score,[expr $p2_score + $new_p2],p1) [list $p1_wins $p2_wins]
                }

                # Increment the wins
                incr tot_p1_wins $p1_wins
                incr tot_p2_wins $p2_wins
            }
        }
    }

    # Return the result after all rolls
    return [list $tot_p1_wins $tot_p2_wins]
}

set p1 $p1_start
set p2 $p2_start

lassign [game $p1 $p2 0 0 p1] p1_wins p2_wins

puts "Most wins: [expr max($p1_wins, $p2_wins)]"
