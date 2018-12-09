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

# Parse the input
regexp {([[:digit:]]*) players; last marble is worth ([[:digit:]]*) points} $indata _match players last_marble

# Get the next marble in the circle
proc get_next {current} {
    global circle

    return [lindex $circle($current) 0]
}

# Get the previous marble in the circle
proc get_previous {current} {
    global circle

    return [lindex $circle($current) 1]
}

# Insert a marble in the circle just after current
proc insert {current insertion} {
    global circle

    set next [get_next $current]

    set circle($current)   [list $insertion [lindex $circle($current) 1]]
    set circle($insertion) [list $next $current]
    set circle($next)      [list [lindex $circle($next) 0] $insertion]
}

# Remove a marble from the circle
proc delete {deletion} {
    global circle

    set previous [get_previous $deletion]
    set next     [get_next     $deletion]

    unset circle($deletion)
    set circle($previous) [list $next [lindex $circle($previous) 1]]
    set circle($next)     [list [lindex $circle($next) 0] $previous]
}

# Print the circle (only used for debug)
proc print {} {
    set current 0
    while {1} {
        puts -nonewline "$current "
        set current [get_next $current]
        if {$current == $start} {
            break
        }
    }

    puts ""
}

# Gets the maximum score that any player has
proc get_max_score {} {
    global scores

    set max 0
    foreach {key value} [array get scores] {
        if {$value > $max} {
            set max $value
        }
    }
    return $max
}

# Initialize the circle. Each marble keeps track of the next and previous marble
# in the circle {next previous}
set circle(0) [list 0 0]

set current 0
set player 1

# Start the game
for {set marble 1} {$marble <= [expr $last_marble * 100]} {incr marble} {
    # Special case when current marble is a multiple of 23
    if {[expr $marble % 23] == 0} {
        # Handling the circle
        set seven $current
        for {set i 0} {$i < 7} {incr i} {
            set seven [get_previous $seven]
        }
        set current [get_next $seven]
        delete $seven

        # Calculate the new score
        set score 0
        if {[info exists scores($player)]} {
            set score $scores($player)
        }
        set scores($player) [expr $score + $marble + $seven]
    } else {
        # Inserting the marble in the circle
        set current [get_next $current]
        insert $current $marble
        set current $marble
    }

    # Handling current player
    incr player
    if {$player > $players} {
        set player 1
    }

    # For printing the answer to part 1
    if {$marble == $last_marble} {
        puts "Largest score (x 1)  : [get_max_score]"
    }
}

puts "Largest score (x 100): [get_max_score]"
