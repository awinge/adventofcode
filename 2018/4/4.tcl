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

set indata [lsort $indata]
foreach data $indata {
    if {[regexp {\[([0-9]*)-([0-9]*)-([0-9]*) ([0-9]*):([0-9]*)\] (.*)} $data _match year month day hour minute what]} {
        if {$minute != "00"} {
            set minute [string trimleft $minute 0]
        }
        lappend schedule [list $minute $what]
    }
}

proc save_guard_sleep {id shift} {
    global guard_sleep
    if {[info exists guard_sleep($id)]} {
        set guard_sleep($id) [lmap a $guard_sleep($id) b $shift {expr $a + $b}]
    } else {
        set guard_sleep($id) $shift
    }
}

proc find_max_index {a} {
    set max_index 0
    set index 0
    foreach value $a {
        if {![info exists max] ||
            $value > $max} {
            set max $value
            set max_index $index
        }
        incr index
    }

    return $max_index
}

set id -1
foreach event $schedule {
    set minute [lindex $event 0]
    set what   [lindex $event 1]

    if {[regexp {Guard #([0-9]*) begins} $what _match new_id]} {
        # Save data from the last guard
        if {$id != -1} {
            save_guard_sleep $id $shift
        }
        set shift [lrepeat 60 "0"]
        set id $new_id
        continue
    }

    if {[regexp {falls asleep} $what _match]} {
        set sleep_start $minute
        continue
    }

    if {[regexp {wakes up} $what _match]} {
        for {set i $sleep_start} {$i < $minute} {incr i} {
            lset shift $i "1"
        }
        continue
    }
}
save_guard_sleep $id $shift

set most_sleep_minutes 0
foreach {id sleep} [array get guard_sleep] {
    set sleep_minutes 0
    foreach minute $sleep {
        set sleep_minutes [expr $sleep_minutes + $minute]
    }

    if {$sleep_minutes > $most_sleep_minutes} {
        set most_sleeping_guard $id
        set most_sleep_minutes  $sleep_minutes
    }
}

set most_sleeping_minute [find_max_index $guard_sleep($most_sleeping_guard)]

puts "Guard ID:       $most_sleeping_guard"
puts "Sleep minutes:  $most_sleep_minutes"
puts "Most sleep min: $most_sleeping_minute"
puts "ID * minute:    [expr $most_sleeping_guard * $most_sleeping_minute]"
puts ""

set total_max 0
foreach {id sleep} [array get guard_sleep] {
    set max_index [find_max_index $sleep]
    set current_max [lindex $sleep $max_index]

    if {$current_max > $total_max} {
        set guard_id_max $id
        set max_minute $max_index
        set total_max $current_max
    }
}

puts "Guard ID:     $guard_id_max"
puts "Sleep minute: $max_minute"
puts "ID * minute:  [expr $guard_id_max * $max_minute]"
