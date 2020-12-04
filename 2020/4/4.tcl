#!/usr/bin/tclsh

# Read the file
set fp [open "input" r]
set fd [read $fp]
close $fp

# Clean the input
foreach row [split $fd "\n"] {
    lappend indata $row
}

set fields {byr iyr eyr hgt hcl ecl pid}

# Zero all fields
foreach field $fields {
    set $field 0
}

# Loop over data
foreach data $indata {

    # Empty line, check validity
    if {$data == ""} {

        # Check that all field exists
        set ok 1
        foreach field $fields {
            if {[set $field] == 0} {
                set ok 0
                break
            }
        }

        if {$ok == 1} {
            # All files existed
            incr valid

            # Additional value checks
            foreach field $fields {
                set content [set $field]
                switch $field {
                    byr {
                        if {[string length $content] == 4 &&
                            $content >= 1920 && $content <= 2002} {
                            continue
                        }
                    }
                    iyr {
                        if {[string length $content] == 4 &&
                            $content >= 2010 && $content <= 2020} {
                            continue
                        }
                    }
                    eyr {
                        if {[string length $content] == 4 &&
                            $content >= 2020 && $content <= 2030} {
                            continue
                        }
                    }
                    hgt {
                        if {[regexp {([0-9]*)cm} $content match cm]} {
                            if {$cm >= 150 && $cm <= 193} {
                                continue
                            }
                        }
                        if {[regexp {([0-9]*)in} $content match inch]} {
                            if {$inch >= 59 && $inch <= 76} {
                                continue
                            }
                        }
                    }
                    hcl {
                        if {[regexp {\#([a-f0-9]*)} $content match color]} {
                            if {[string length $color] == 6} {
                                continue
                            }
                        }
                    }
                    ecl {
                        if {[regexp {(amb|blu|brn|gry|grn|hzl|oth)} $content match]} {
                            continue
                        }
                    }
                    pid {
                        if {[regexp {([0-9]*)} $content match passid]} {
                            if {[string length $passid] == 9} {
                                continue
                            }
                        }
                    }
                }
                set ok 0
                break
            }
        }

        if {$ok == 1} {
            # Value checks ok
            incr strictvalid
        }

        # zero all fileds for next passport
        foreach field $fields {
            set $field 0
        }
        continue
    }

    # Parse data into each field variable
    foreach field $fields {
        if {[regexp "$field:(\[a-z0-9#\]*)" $data match content]} {
            set $field $content
        }
    }
}

puts "Valid passports: $valid"
puts "Strict valid passports: $strictvalid"
