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
    if {[regexp {([a-z ]+) \(contains (.*)\)} $data match ingredients allergens]} {
        set ingredients [split $ingredients " "]

        # Count occurences of each ingredient
        foreach ingredient $ingredients {
            incr ingredient_count($ingredient)
        }

        foreach allergen [split $allergens ","] {
            set allergen [string trim $allergen " "]

            if {$allergen != ""} {
                lappend foods_with_allergen($allergen) $ingredients
            }
        }
        continue
    }

    puts "Unparsed: $data"
}

# Go through all foods containing an allergen and check which ingredient(s)
# that are present in all foods.
foreach {allergen foods} [array get foods_with_allergen] {
    set first_food [lindex $foods 0]

    set possible_ingredients {}
    foreach first_ingredient $first_food {
        set found_in_all 1
        foreach food [lrange $foods 1 end] {
            if {[lsearch -exact $food $first_ingredient] == -1} {
                set found_in_all 0
                break
            }
        }
        if {$found_in_all == 1} {
            lappend possible_ingredients     $first_ingredient
            lappend all_possible_ingredients $first_ingredient
        }
    }

    set allergen_to_ingredients($allergen) $possible_ingredients
}

set ans 0
foreach {k v} [array get ingredient_count] {
    if {[lsearch -exact $all_possible_ingredients $k] == -1} {
        incr ans $v
    }
}

puts "Occurences of non-allergen ingredients: $ans"

while 1 {
    set done 1
    foreach {allergen ingredients} [array get allergen_to_ingredients] {
        if {[llength $ingredients] == 1} {
            set single_ingredient [lindex $ingredients 0]
            set ingredient_to_allergen($single_ingredient) $allergen
            continue
        }

        set done 0

        set new_ingredients {}
        foreach ingredient $ingredients {
            if {![info exists ingredient_to_allergen($ingredient)]} {
                lappend new_ingredients $ingredient
            }
        }
        set allergen_to_ingredients($allergen) $new_ingredients
    }

    if {$done == 1} {
        break
    }
}

# Compose a mapping list with allergen / ingredient pairs
foreach {ingredient allergen} [array get ingredient_to_allergen] {
    lappend mappings [list $allergen $ingredient]
}

# Sort by allergen
set mappings [lsort -index 0 $mappings]

# Get only the ingredients
set ingredients {}
foreach mapping $mappings {
    lappend ingredients [lindex $mapping 1]
}

puts "Canonical dangerous ingredient list: [join $ingredients ,]"
