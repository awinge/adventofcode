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

# Get the row from a boarding pass
proc row {pass} {
    set pass [string range $pass 0 6]
    set bin 1
    set row 0

    foreach char [lreverse [split $pass ""]] {
        if {$char == "B"} {
            set row [expr $row + $bin]
        }
        set bin [expr $bin * 2]
    }
    return $row
}

# Get the column from a boarding pass
proc column {pass} {
    set pass [string range $pass 7 9]
    set bin 1
    set column 0

    foreach char [lreverse [split $pass ""]] {
        if {$char == "R"} {
            set column [expr $column + $bin]
        }
        set bin [expr $bin * 2]
    }

    return $column
}

# Get ID from a row and column
proc id {row column} {
    set id [expr $row * 8 + $column]
    return $id
}

# Create a represenation for the plane for occupation
for {set row 0} {$row < 128} {incr row} {
    for {set column 0} {$column < 8} {incr column} {
        set plane($row,$column) 0
    }
}

set max_id 0
foreach data $indata {
    set row    [row $data]
    set column [column $data]
    set id     [id $row $column]

    # Mark IDs taken
    set ids($id) 1

    # Remove taken seats from plane representation
    unset plane($row,$column)

    # Check for max ID
    if {$id > $max_id} {
        set max_id $id
    }
}

puts "Max ID: $max_id"

# Loop through the non-taken seats
foreach {key value} [array get plane] {
    lassign [split $key ","] row column
    set id [id $row $column]

    # IDs next to the free seat shall be taken
    if {[info exists ids([expr $id + 1])] &&
        [info exists ids([expr $id - 1])]} {
        puts "My ID: $id"
    }
}
