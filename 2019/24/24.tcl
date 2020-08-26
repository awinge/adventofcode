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

set y 0
foreach data $indata {
    set x 0
    foreach char [split $data ""] {
        set eris($x,$y) $char
        incr x
    }
    incr y
}

# Get boundaries of eris
proc get_boundaries {} {
    upvar 1 eris eris
    
    foreach {key value} [array get eris] {
        lassign [split $key ","] x y
        
        if {![info exists min_x] || $x < $min_x} {
            set min_x $x
        }
        
        if {![info exists max_x] || $x > $max_x} {
            set max_x $x
        }
        
        if {![info exists min_y] || $y < $min_y} {
            set min_y $y
        }
        
        if {![info exists max_y] || $y > $max_y} {
            set max_y $y
        }
    }
    return [list $min_x $min_y $max_x $max_y]
}

proc print {} {
    upvar 1 eris eris
    
    lassign [get_boundaries] min_x min_y max_x max_y
    
    for {set y $min_y} {$y <= $max_y} {incr y} {
        for {set x $min_x} {$x <= $max_x} {incr x} {
            if {[info exists eris($x,$y)]} {
                puts -nonewline "$eris($x,$y)"
            } else {
                puts -nonewline " "
            }
        }
        puts ""
    }
}

proc stringify {} {
    upvar 1 eris eris

    for {set y 0} {$y <= 4} {incr y} {
        for {set x 0} {$x <= 4} {incr x} {
            lappend all $eris($x,$y)
        }
    }
    return [join $all ""]
}

proc get_count {x y} {
    upvar 1 eris eris

    set left  "[expr $x-1],$y"
    set right "[expr $x+1],$y"
    set up    "$x,[expr $y-1]"
    set down  "$x,[expr $y+1]"

    set count 0

    foreach coord [list $left $right $up $down] {
        if {[info exist eris($coord)] && $eris($coord) == "#"} {
            incr count
        }
    }
    return $count
}


proc minute {} {
    upvar 1 eris eris

    foreach {k v} [array get eris] {
        lassign [split $k ","] x y
        set count [get_count $x $y]

        switch $v {
            \# {
                if {$count == 1} {
                    set new_eris($k) #
                } else {
                    set new_eris($k) .
                }
            }
            . {
                if {$count == 1 || $count == 2} {
                    set new_eris($k) #
                } else {
                    set new_eris($k) .
                }
            }
        }
    }

    array set eris [array get new_eris]
}

proc rating {} {
    upvar 1 eris eris

    set points 0
    set worth  1

    foreach tile [split [stringify] ""] {
        if {$tile == "#"} {
            incr points $worth
        }
        set worth [expr $worth * 2]
    }
    return $points
}



while 1 {
    set s [stringify]

    if {[info exists layout($s)]} {
        break
    }
    set layout([stringify]) 1
    minute
}

puts "First matching previous:"
print
puts "Biodiversity rating: [rating]"


## Part II
set y 0
foreach data $indata {
    set x 0
    foreach char [split $data ""] {
        if {$x != 2 || $y != 2} {
            set folderis($x,$y,0) $char
        }
        incr x
    }
    incr y
}

# Returns a list of coordinates to consider
proc get_folded_coords {x y z dir} {
    switch $dir {
        left {
            incr x -1
        }
        right {
            incr x +1
        }
        up {
            incr y -1
        }
        down {
            incr y +1
        }
        default {
            puts "wrong dir"
            exit
        }
    }

    # Check for folding
    if {$x == 2 && $y == 2} {
        incr z +1
        switch $dir {
            left {
                set x 4
                for {set y 0} {$y <= 4} {incr y} {
                    lappend coords [list $x $y $z]
                }
                return $coords
            }
            right {
                set x 0
                for {set y 0} {$y <= 4} {incr y} {
                    lappend coords [list $x $y $z]
                }
                return $coords
            }
            up {
                set y 4
                for {set x 0} {$x <= 4} {incr x} {
                    lappend coords [list $x $y $z]
                }
                return $coords
            }
            down {
                set y 0
                for {set x 0} {$x <= 4} {incr x} {
                    lappend coords [list $x $y $z]
                }
                return $coords
            }
        }
    }

    if {$x < 0} {
        incr z -1
        set x 1
        set y 2
    }
    
    if {$x > 4} {
        incr z -1
        set x 3
        set y 2
    }
    
    if {$y < 0} {
        incr z -1
        set x 2
        set y 1
    }
    
    if {$y > 4} {
        incr z -1
        set x 2
        set y 3
    }
    
    return [list [list $x $y $z]]
}

# Returns the number of surrounding bugs
proc get_folded_count {x y z} {
    upvar 1 folderis folderis

    set count 0

    foreach dir [list left right up down] {
        set coords [get_folded_coords $x $y $z $dir]

        foreach coord $coords {
            lassign $coord cx cy cz
            if {[info exist folderis($cx,$cy,$cz)] && $folderis($cx,$cy,$cz) == "#"} {
                incr count
            }
        }
    }
    return $count
}

# Prepare by putting "." on adjacent bugs
proc prep_folderis {} {
    upvar 1 folderis folderis
    
    foreach {k v} [array get folderis] {
        if {$v == "#"} {
            lassign [split $k ","] x y z

            foreach dir [list left right up down] {
                set coords [get_folded_coords $x $y $z $dir]

                foreach coord $coords {
                    lassign $coord cx cy cz
                    if {![info exist folderis($cx,$cy,$cz)]} {
                        set folderis($cx,$cy,$cz) .
                    }
                }
            }
        }
    }
}

# Run one minute with folding
proc folded_minute {} {
    upvar 1 folderis folderis

    prep_folderis
    
    foreach {k v} [array get folderis] {
        lassign [split $k ","] x y z
        set count [get_folded_count $x $y $z]

        switch $v {
            \# {
                if {$count == 1} {
                    set new_folderis($k) #
                } else {
                    set new_folderis($k) .
                }
            }
            . {
                if {$count == 1 || $count == 2} {
                    set new_folderis($k) #
                } else {
                    set new_folderis($k) .
                }
            }
        }
    }

    array set folderis [array get new_folderis]
}

# Get boundaries of folderis help to print
proc get_folded_boundaries {} {
    upvar 1 folderis folderis
    
    foreach {key value} [array get folderis] {
        lassign [split $key ","] x y z
        
        if {![info exists min_x] || $x < $min_x} {
            set min_x $x
        }
        
        if {![info exists max_x] || $x > $max_x} {
            set max_x $x
        }
        
        if {![info exists min_y] || $y < $min_y} {
            set min_y $y
        }
        
        if {![info exists max_y] || $y > $max_y} {
            set max_y $y
        }

        if {![info exists min_z] || $z < $min_z} {
            set min_z $z
        }
        
        if {![info exists max_z] || $z > $max_z} {
            set max_z $z
        }
    }
    return [list $min_x $min_y $min_z $max_x $max_y $max_z]
}

proc print_folded {} {
    upvar 1 folderis folderis
    
    lassign [get_folded_boundaries] min_x min_y min_z max_x max_y max_z
    
    for {set z $min_z} {$z <= $max_z} {incr z} {
        puts "Depth: $z"
        for {set y $min_y} {$y <= $max_y} {incr y} {
            for {set x $min_x} {$x <= $max_x} {incr x} {
                if {[info exists folderis($x,$y,$z)]} {
                    puts -nonewline "$folderis($x,$y,$z)"
                } else {
                    puts -nonewline " "
                }
            }
            puts ""
        }
        puts ""
    }
    
}

# Run the 200 minutes 
for {set i 0} {$i < 200} {incr i} {
    folded_minute
}

# Used for debug
#print_folded

# Counting the number of bugs
set count 0
foreach {k v} [array get folderis] {
    if {$v == "#"} {
        incr count
    }
}

puts "Number of bugs: $count"
