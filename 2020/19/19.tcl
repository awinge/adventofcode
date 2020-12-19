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

# Parse the indata
# Creates rules array containing list of list of rules
# Creates a list of messages (messages)
foreach data $indata {
    if {[regexp {([0-9]+): ([0-9 \|]+)} $data match rulenum content]} {
        set subrule {}
        foreach sub [split $content "|"] {
            set subsubrule {}
            set sub [string trim $sub " "]
            foreach subsub [split $sub " "] {
                lappend subsubrule $subsub
            }
            lappend subrule $subsubrule
        }

        set rules($rulenum) $subrule

        continue
    }

    if {[regexp {([0-9]+): "([a-z]*)"} $data match rulenum content]} {
        set rules($rulenum) $content
        continue
    }

    if {[regexp {[ab]+} $data match]} {
        lappend messages $match
        continue
    }

    puts "Did not parse: $data"
    exit
}

# Creates a regular expression for rule num
# Part2 is set if part2 rules shall be used
proc regexp_rule {num part2} {
    upvar 1 rules rules

    set content $rules($num)
    if {$content == "a" || $content == "b"} {
        return $content
    }

    # Changed rules for part 2
    #  8: 42 | 42 8
    #  11: 42 31 | 42 11 31
    if {$part2 == 1} {
        switch $num {
            8 {
                # Solved directly with regexp quantifier
                return "([regexp_rule 42 1])+"
            }
            11 {
                # "()" matches nothing in the current regexp
                # It is used for additional rule 11 expansion
                return "[regexp_rule 42 1]()[regexp_rule 31 1]"
            }
        }
    }

    foreach ruleset $content {
        set sub ""
        foreach rule $ruleset {
            set sub "$sub[regexp_rule $rule $part2]"
        }
        lappend ret $sub
    }
    return "([join $ret "|"])"
}

# Check the number for messages matching
set matching 0
foreach m $messages {
    if {[regexp ^[regexp_rule 0 0]$ $m]} {
        incr matching
    }
}

puts "Matching rules: $matching"

# Expand rule 0 with part2 rules
# Loop
#   Count the messages matching
#   Expand looping rules 11
# Until no matching messages are found
set rule [regexp_rule 0 1]
set matching 0
while 1 {
    set new_matches 0
    foreach m $messages {
        if {[regexp ^[set rule]$ $m]} {
            incr new_matches
        }
    }
    if {$new_matches > 0} {
        incr matching $new_matches
    } else {
        break
    }

    # Find "()" for rule 11 expansion
    set index [string first "()" $rule]
    set rule [string replace $rule $index [expr $index + 1] "[regexp_rule 42 1]()[regexp_rule 31 1]"]
}

puts "Matching rules: $matching"
