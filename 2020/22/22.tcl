#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	lappend indata $row
    }
}

# Create the decks of each player as p1 and p2
foreach data $indata {
    if {[regexp {Player ([0-9]*):} $data match player]} {
        continue
    }

    if {[regexp {([0-9]*)} $data match value]} {
        lappend p${player} $value
        continue
    }

    puts "Unparsed: $data"
}

# Calculate the score of a deck
proc score {deck} {
    set mul 1
    foreach card [lreverse $deck] {
        incr score [expr $mul * $card]
        incr mul
    }

    return $score
}

# The game of combat
# Returns the winner and the winning deck
proc combat {p1_deck p2_deck} {
    while {$p1_deck != [] && $p2_deck != []} {
        # Deal each player a card
        set p1_card [lindex $p1_deck 0]
        set p2_card [lindex $p2_deck 0]
        set p1_deck [lrange $p1_deck 1 end]
        set p2_deck [lrange $p2_deck 1 end]

        # Give the player that won the cards
        if {$p1_card > $p2_card} {
            lappend p1_deck $p1_card $p2_card
        } else {
            lappend p2_deck $p2_card $p1_card
        }
    }

    # Game has ended, return the winner and the winning deck
    if {$p1_deck == []} {
        return [list 2 $p2_deck]
    } else {
        return [list 1 $p1_deck]
    }
}

# Play combat
lassign [combat $p1 $p2] winner winner_deck

puts "Winner player $winner, with score: [score $winner_deck]"

# The game of recursive combat
# Returns the winner and the winning deck
proc recursive_combat {p1_deck p2_deck} {
    set p1_orig $p1_deck
    set p2_orig $p2_deck

    while {$p1_deck != [] && $p2_deck != []} {
        # Check for recursion
        if {[info exist configs($p1_deck,$p2_deck)]} {
            return [list 1 $p1_deck]
        }
        set configs($p1_deck,$p2_deck) 1

        # Deal each player a card
        set p1_card [lindex $p1_deck 0]
        set p2_card [lindex $p2_deck 0]
        set p1_deck [lrange $p1_deck 1 end]
        set p2_deck [lrange $p2_deck 1 end]

        # Initate subgame
        if {$p1_card <= [llength $p1_deck] &&
            $p2_card <= [llength $p2_deck]} {

            lassign [recursive_combat [lrange $p1_deck 0 [expr $p1_card - 1]] [lrange $p2_deck 0 [expr $p2_card - 1]]] winner winner_deck
        } else {
            # With no subgame just check the value of the cards
            if {$p1_card > $p2_card} {
                set winner 1
            } else {
                set winner 2
            }
        }

        # Give cards to the winning player
        if {$winner == 1} {
            lappend p1_deck $p1_card $p2_card
        } else {
            lappend p2_deck $p2_card $p1_card
        }
    }

    # Game has ended, return the winner and the winning deck
    if {$p1_deck == []} {
        return [list 2 $p2_deck]
    } else {
        return [list 1 $p1_deck]
    }
}

# Play Recursive Combat
lassign [recursive_combat $p1 $p2] winner winner_deck

puts "Winner player $winner, with score: [score $winner_deck]"
