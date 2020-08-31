#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    if {$row != ""} {
	lappend indata [regexp -inline -all -- {\S+} $row]
    }
}

proc parse {indata} {
    foreach data $indata {
        if {[regexp {deal with increment ([0-9]+)} $data match increment]} {
            lappend parsed_input [list dwi $increment]
            continue
        }
        
        if {[regexp {deal into new stack} $data]} {
            lappend parsed_input [list dins]
            continue
        }
        
        if {[regexp {cut ([0-9-]+)} $data match where]} {
            lappend parsed_input [list c $where]
            continue
        }

        puts "Unparsed $data"
        exit
    }
    return $parsed_input
}


proc reduce_cut {operations no_of_cards} {
    set i 0
    while {$i < [expr [llength $operations] - 1]} {
        set current [lindex $operations $i 0]
        set next    [lindex $operations [expr $i + 1] 0]

        if {$current == "c" && $next == "c"} {
            set current_data [lindex $operations $i 1]
            set next_data    [lindex $operations [expr $i + 1] 1]

            set operations [lreplace $operations $i [expr $i + 1] [list c [expr ($current_data + $next_data) % $no_of_cards]]]
        } else {
            incr i
        }
    }
    return $operations
}

proc reduce_dwi {operations no_of_cards} { 
    set i 0
    while {$i < [expr [llength $operations] - 1]} {
        set current [lindex $operations $i 0]
        set next    [lindex $operations [expr $i + 1] 0]

        if {$current == "dwi" && $next == "dwi"} {
            set current_data [lindex $operations $i 1]
            set next_data    [lindex $operations [expr $i + 1] 1]

            set operations [lreplace $operations $i [expr $i + 1] [list dwi [expr ($current_data * $next_data) % $no_of_cards]]]
        } else {
            incr i
        }
    }
    return $operations
}   

proc reduce_dins {operations} { 
    set i 0
    while {$i < [expr [llength $operations] - 1]} {
        set current [lindex $operations $i 0]
        set next    [lindex $operations [expr $i + 1] 0]

        if {$current == "dins" && $next == "dins"} {
            set current_data [lindex $operations $i 1]
            set next_data    [lindex $operations [expr $i + 1] 1]

            set operations [lreplace $operations $i [expr $i + 1]]
        } else {
            incr i
        }
    }
    return $operations
}   

proc tansform_c_dwi_to_dwi_c {operations no_of_cards} {
    set i 0
    while {$i < [expr [llength $operations] - 1]} {
        set current  [lindex $operations $i 0]
        set next     [lindex $operations [expr $i + 1] 0]

        if {$current == "c" && $next == "dwi"} {
            set current_data  [lindex $operations $i 1]
            set next_data     [lindex $operations [expr $i + 1] 1]
            
            set operations [lreplace $operations $i $i [list dwi $next_data]]
            incr i
            set operations [lreplace $operations $i $i [list c [expr ($current_data * $next_data) % $no_of_cards]]]
        } else {
            incr i
        }
    }
    return $operations
}

proc transform_c_dins_to_dins_c {operations} {
    set i 0
    while {$i < [expr [llength $operations] - 1]} {
        set current  [lindex $operations $i 0]
        set next     [lindex $operations [expr $i + 1] 0]

        if {$current == "c" && $next == "dins"} {
            set current_data  [lindex $operations $i 1]
            
            set operations [lreplace $operations $i $i [list dins]]
            incr i
            set operations [lreplace $operations $i $i [list c [expr -$current_data]]]
        } else {
            incr i
        }
    }
    return $operations
}

proc transform_dins_dwi_to_dwi_dins_c {operations} {
    set i 0
    while {$i < [expr [llength $operations] - 1]} {
        set current  [lindex $operations $i 0]
        set next     [lindex $operations [expr $i + 1] 0]

        if {$current == "dins" && $next == "dwi"} {
            set next_data [lindex $operations [expr $i + 1] 1]
            
            set operations [lreplace $operations $i $i [list $next $next_data]]
            incr i
            set operations [lreplace $operations $i $i [list $current] [list c [expr $next_data - 1]]]
        } else {
            incr i
        }
    }
    return $operations
}

proc minimize_operations {operations no_of_cards} {
    while 1 {
        set orig_operations $operations
        set operations [tansform_c_dwi_to_dwi_c $operations $no_of_cards]
        set operations [transform_c_dins_to_dins_c $operations]
        set operations [transform_dins_dwi_to_dwi_dins_c $operations]
        set operations [reduce_cut $operations $no_of_cards]
        set operations [reduce_dwi $operations $no_of_cards]
        set operations [reduce_dins $operations]

        if {$orig_operations == $operations} {
            return $operations
        }
    }
}

proc print {operations} {
    foreach operation $operations {
        set action [lindex $operation 0]

        switch $action {
            dwi {
                set increment [lindex $operation 1]

                puts "deal with increment $increment"
            }
            dins {
                puts "deal into new stack"
            }
            c {
                set where [lindex $operation 1]
                puts "cut $where"
            }
            default {
                puts "Strange action $action"
                exit
            }
        }
    }
}

proc deal {operations cards} {
    foreach operation $operations {
        set action [lindex $operation 0]

        switch $action {
            dwi {
                set increment [lindex $operation 1]
                
                set new_index 0 
                set new_cards $cards
                foreach card $cards {
                    set new_cards [lreplace $new_cards $new_index $new_index $card]
                    set new_index [expr ($new_index + $increment) % [llength $cards]]
                }
                set cards $new_cards
            }
            dins {
                set cards [lreverse $cards]
            }
            c {
                set where [lindex $operation 1]
                if {$where < 0} {
                    set where [expr $where + [llength $cards]]
                }
                set first [lrange $cards 0 [expr $where - 1]]
                set second [lrange $cards $where end]

                set cards [list {*}$second {*}$first]
            }
            default {
                puts "Strange action $action"
                exit
            }
        }
    }
    return $cards
}

proc deal_pos {operations pos no_of_cards} {
    foreach operation $operations {
        set action [lindex $operation 0]

        switch $action {
            dwi {
                set increment [lindex $operation 1]
                
                set pos [expr ($pos * $increment) % $no_of_cards]
            }
            dins {
                set pos [expr $no_of_cards - $pos - 1]
            }
            c {
                set where [lindex $operation 1]
                if {$pos >= $where} {
                    set pos [expr $pos - $where]
                } else {
                    set pos [expr $no_of_cards - $where + $pos]
                }
            }
            default {
                puts "Strange action $action"
                exit
            }
        }
    }
    return $pos
}

proc gcd_extend {a b} {
    if {$a == 0} {
        return [list $b 0 1]
    }

    lassign [gcd_extend [expr $b % $a] $a] gcd x1 y1
    set x [expr $y1 - ($b/$a) * $x1]
    set y $x1

    return [list $gcd $x $y]
}

proc mod_inverse {a m} {
    lassign [gcd_extend $a $m] g x y

    if {$g != 1} {
        puts "No Inverse exists"
        exit
    } else {
        return [expr (($x % $m) + $m) % $m]
    }
}

proc deal_pos_reverse {operations pos no_of_cards} {
    foreach operation [lreverse $operations] {
        set action [lindex $operation 0]

        switch $action {
            dwi {
                set increment [lindex $operation 1]
                
                set increment_inverse [mod_inverse $increment $no_of_cards]
                set pos [expr ($pos * $increment_inverse) % $no_of_cards]
            }
            dins {
                set pos [expr $no_of_cards - $pos - 1]
            }
            c {
                set where [expr -[lindex $operation 1]]
                if {$pos >= $where} {
                    set pos [expr $pos - $where]
                } else {
                    set pos [expr $no_of_cards - $where + $pos]
                }
            }
            default {
                puts "Strange action $action"
                exit
            }
        }
        
    }
    return $pos
}    

set no_of_cards 10007

set operations [parse $indata]
set operations [minimize_operations $operations $no_of_cards]

puts "Card 2019 has position: [deal_pos $operations 2019 $no_of_cards]"

# PART II

set no_of_cards 119315717514047
set iterations 101741582076661

set operations [parse $indata]
set operations [minimize_operations $operations $no_of_cards]
 
proc iterate_operations {operations iterations no_of_cards} {
    set power_operations $operations
    set result_operations []
    while {$iterations > 0} {
        if {[expr $iterations % 2]} {
            set result_operations [list {*}$result_operations {*}$power_operations]
        }
        set iterations [expr $iterations / 2]
        set power_operations [list {*}$power_operations {*}$power_operations]
        set power_operations [minimize_operations $power_operations $no_of_cards]
    }
    return $result_operations
}

set operations [iterate_operations $operations $iterations $no_of_cards]
set operations [minimize_operations $operations $no_of_cards]

puts "Card in position 2020: [deal_pos_reverse $operations 2020 $no_of_cards]"
