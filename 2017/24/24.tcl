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

foreach data $indata {
    lappend bridges [split $data /]
}

proc max_strength {bridges pins bonus_per_level} {
    set max 0
    foreach index [lsearch -all -index 0 $bridges $pins] {
        set outpins [lindex $bridges $index 1]
        set mybridges [lreplace $bridges $index $index]
        set local_max [expr $bonus_per_level + $pins + $outpins + [max_strength $mybridges $outpins $bonus_per_level]]
        if {$local_max > $max} {
            set max $local_max
        }
    }
    foreach index [lsearch -all -index 1 $bridges $pins] {
        set outpins [lindex $bridges $index 0]
        set mybridges [lreplace $bridges $index $index]
        set local_max [expr $bonus_per_level + $pins + $outpins + [max_strength $mybridges $outpins $bonus_per_level]]
        if {$local_max > $max} {
            set max $local_max
        }
    }
    return $max
}

puts "Maximum strength: [max_strength $bridges 0 0]"
puts "Maximum strength of longest: [expr [max_strength $bridges 0 100000] % 100000]"
