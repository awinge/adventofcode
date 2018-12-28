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

# Parsing the input
set parse_immune 1
foreach data $indata {

    # Regexp for switching reading immune system to infection
    if {[regexp {Infection.*} $data]} {
        set parse_immune 0
        continue
    }

    if {[regexp {([\d]*) units each with ([\d]*) hit points(.*) with an attack that does ([\d]*) (.*) damage at initiative ([\d]*)} $data _match units hp weak_strength attack_power attack_type initiative]} {

        set weak [list]
        set immune [list]

        if {[regexp {weak to ([a-z, ]*)} $weak_strength _match weaknesses]} {
            foreach weakness [split $weaknesses ", "] {
                if {$weakness != ""} {
                    lappend weak $weakness
                }
            }
        }
        if {[regexp {immune to ([a-z, ]*)} $weak_strength _match immunities]} {
            foreach immunity [split $immunities ", "] {
                if {$immunity != ""} {
                    lappend immune $immunity
                }
            }
        }

        if {$parse_immune} {
            lappend immune_system [list $units $hp [list $attack_power $attack_type] $initiative $weak $immune]
        } else {
            lappend infection [list $units $hp [list $attack_power $attack_type] $initiative $weak $immune]
        }
    }
}

# Get the effective power of a group
proc get_power {group} {
    lassign $group u hp attack i
    lassign $attack attack_power attack_type
    return [expr $u * $attack_power]
}

# Get the initiative of a group
proc get_initiative {group} {
    return [lindex $group 3]
}

# Create a list with effective power and initiative and an index to the group list
# sort it by initiative and then effective power (effective power gets priority)
# and then return the indexess
proc get_targeting_order {groups} {
    set index -1
    set power [lmap g $groups { list [get_power $g] [get_initiative $g] [incr index] }]

    set power [lsort -integer -decreasing -index 0 [lsort -integer -decreasing -index 1 $power]]

    return [lmap p $power { lindex $p 2 }]
}

# Calculate how much damage an attacking group does on a defending one
proc get_damage {attack_group defense_group} {
    lassign $attack_group _units _hp attack _initative _weak _immune
    lassign $attack attack_power attack_type
    lassign $defense_group _units _hp _attack _initative weak immune

    if {[lsearch $immune $attack_type] != -1} {
        return 0
    }

    if {[lsearch $weak $attack_type] != -1} {
        return [expr 2 * [get_power $attack_group]]
    }

    return [get_power $attack_group]
}

# Returns a list of attacker pairs {attacker defender}
# The returned list is sorted in the order the attacks will occur
proc get_attacks {groups divider} {
    set attacks [list]
    set defending [lrepeat [llength $groups] 0]

    set targeting_order [get_targeting_order $groups]
    foreach attack_index $targeting_order {
        set attacker            [lindex $groups $attack_index]
        set attacker_power      [get_power $attacker]
        set attacker_initiative [get_initiative $attacker]

        if {$attack_index < $divider} {
            set defend_min_index $divider
            set defend_max_index [llength $groups]
        } else {
            set defend_min_index 0
            set defend_max_index [expr $divider -1]
        }

        set max_damage     0
        set max_index      -1
        set max_power      0
        set max_initiative 0
        for {set i $defend_min_index} {$i <= $defend_max_index} {incr i} {
            if {[lindex $defending $i] == 0} {
                set defender       [lindex $groups $i]
                set defender_units [lindex $defender 0]
                set damage         [get_damage $attacker $defender]
                set power          [get_power $defender]
                set initiative     [get_initiative $defender]

                if {$defender_units <= 0} {
                    continue
                }

                if {$damage > $max_damage ||
                    ($damage == $max_damage &&
                     $damage > 0 &&
                     ($power > $max_power ||
                      ($power == $max_power &&
                       $initiative > $max_initiative)))} {
                    set max_damage     $damage
                    set max_index      $i
                    set max_power      [get_power $defender]
                    set max_initiative [get_initiative $defender]
                }
            }
        }
        if {$max_damage != 0} {
            lappend attacks [list $attack_index $max_index $attacker_initiative]
            lset defending $max_index 1
        }
    }

    set attacks [lsort -integer -decreasing -index 2 $attacks]

    return [lmap a $attacks { lrange $a 0 1 }]
}

# Resolves one attack and returns the updated groups
proc resolve_attack {groups attacker_index defender_index} {
    set attacker [lindex $groups $attacker_index]
    lassign $attacker attacker_units

    # Attack not possible
    if {$attacker_units <= 0} {
        return $groups
    }

    set defender [lindex $groups $defender_index]
    set damage [get_damage $attacker $defender]

    lassign $defender defending_units defender_hp

    set defending_units [expr $defending_units - ($damage / $defender_hp)]

    if {$defending_units < 0} {
        set defending_units 0
    }
    lset defender 0 $defending_units
    lset groups $defender_index $defender

    return $groups
}

# Proc of returning the number of units in an army specified
# with a start and stop index in groups
proc get_army_units {groups start_index stop_index} {
    for {set i $start_index} {$i <= $stop_index} {incr i} {
        set group [lindex $groups $i]
        incr units [lindex $group 0]
    }
    return $units
}

# Does repetetive targeting / attacks until either one army
# is depleted or further attacks does not change the number of units
# in any group
proc resolve_war {groups divider} {
    while {[get_army_units $groups 0 [expr $divider - 1]] > 0 &&
           [get_army_units $groups $divider [expr [llength $groups] - 1]] > 0} {
        set attacks [get_attacks $groups $divider]

        set new_groups $groups
        foreach attack $attacks {
            lassign $attack attack_index defender_index
            set new_groups [resolve_attack $new_groups $attack_index $defender_index]
        }

        # Nothing happend during the attack
        if {$groups == $new_groups} {
            return $groups
        } else {
            set groups $new_groups
        }
    }
    return $groups
}


set groups [list {*}$immune_system {*}$infection]
set groups [resolve_war $groups [llength $immune_system]]
puts "Units in the winning army: [get_army_units $groups 0 [expr [llength $groups] - 1]]"

# Boosting the attack power of the immune system until it wins
while 1 {
    incr boost
    set immune_system [lmap g $immune_system { lset g 2 0 [expr [lindex $g 2 0] + 1] }]
    set groups [list {*}$immune_system {*}$infection]
    set groups [resolve_war $groups [llength $immune_system]]

    # Exit condition that all infections are eradicated
    if {[get_army_units $groups [llength $immune_system] [expr [llength $groups] - 1]] == 0} {
        break
    }
}
puts "Boosting with $boost, the immune system has [get_army_units $groups 0 [expr [llength $groups] - 1]] units left."
