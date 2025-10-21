catch { rename help ncsim_builtin_help } e

# Generic parameters
set UNDEF        -1

# Verbosity values
set NONE   0
set LOW    100
set MEDIUM 200
set HIGH   300
set FULL   400
set DEBUG  500

set OVM_NONE   $NONE
set OVM_LOW    $LOW
set OVM_MEDIUM $MEDIUM
set OVM_HIGH   $HIGH
set OVM_FULL   $FULL
set OVM_DEBUG  $DEBUG

# Severity values
set INFO    0
set WARNING 1
set ERROR   2
set FATAL   3

set OVM_INFO    $INFO
set OVM_WARNING $WARNING
set OVM_ERROR   $ERROR
set OVM_FATAL   $FATAL

# Style values
set SHORT   138
set LONG    927
set RAW     8

# Action values
set NO_ACTION      0
set DISPLAY        1
set LOG            2
set COUNT          4
set EXIT           8
set CALL_HOOK     16 
set STOP          32

set OVM_NO_ACTION      0
set OVM_DISPLAY        1
set OVM_LOG            2
set OVM_COUNT          4
set OVM_EXIT           8
set OVM_CALL_HOOK     16 
set OVM_STOP          32

# Value types for calling sv wrappers
set SET_VERBOSITY 0
set GET_VERBOSITY 1
set SET_ACTIONS   2
set GET_ACTIONS   3
set SET_STYLE     4
set GET_STYLE     5
set SET_SEVERITY  6
set GET_SEVERITY  7
set ANYSET        100

set EMPTY_STRING          {""}

# Increase packed array probe limit
set probe_packed_limit 32k

proc isnumber {value} {
  set v [string index $value 0]
  if { $v >= 0 && $v <= 9 } { return 1 }
  if { $v == "'" } { return 1 }
  return 0 
}

proc verbosity_to_value { verbosity } {
  global NONE
  global LOW
  global MEDIUM
  global HIGH
  global FULL 
  global DEBUG 

  if { [regexp {^-} $verbosity] } { return -1 }

  switch "$verbosity" {
    "NONE"   { return $NONE }
    "OVM_NONE"   { return $NONE }
    "LOW"    { return $LOW }
    "OVM_LOW"    { return $LOW }
    "MEDIUM" { return $MEDIUM }
    "OVM_MEDIUM" { return $MEDIUM }
    "HIGH"   { return $HIGH }
    "OVM_HIGH"   { return $HIGH }
    "FULL"   { return $FULL }
    "OVM_FULL"   { return $FULL }
    "DEBUG"   { return $DEBUG }
    "OVM_DEBUG"   { return $DEBUG }
  }
  if { ! [isnumber $verbosity] } { return -1 }
  return "$verbosity"
}

proc ovm_get_result {} {
  set result ""
  if { ! [file exists .ovmtclcomm.txt] } { return "" }
  set fid [open .ovmtclcomm.txt r]
  if { [gets $fid result] != -1 } {
    while { [gets $fid line] != -1 } {
      set result "$result\n$line"
    } 
  }
  return $result
}

proc style_to_value { style } {
  global SHORT
  global LONG
  global RAW

  switch "$style" {
    "SHORT" { return $SHORT }
    "OVM_SHORT" { return $SHORT }
    "LONG"  { return $LONG }
    "OVM_LONG"  { return $LONG }
    "RAW"   { return $RAW }
    "OVM_RAW"   { return $RAW }
  }
  return "$style"
}

proc actions_to_value { args } {
  global NO_ACTION
  global DISPLAY
  global LOG
  global COUNT
  global EXIT
  global CALL_HOOK
  global STOP

  set actions [join $args]
  #remove any whitespace
  regsub -all {[ \t\n\b]} $actions {} actions
  #remvoe OVM_ identifers since with/without ovm is okay
  regsub -all {OVM_} $actions {} actions
  #Exit and finish are synonymous
  regsub -all {FINISH} $actions {EXIT} actions
  set alist [split $actions |]
  set rval 0

  for {set i 0} {$i < [llength $alist]} {incr i} {
    if { [regexp NO_ACTION|DISPLAY|LOG|COUNT|EXIT|CALL_HOOK|STOP [lindex $alist $i] ] == 0 } {
      if { ! [isnumber [lindex $alist $i]] } {
#        puts "ovm: *W,NOTACT: the action value [lindex $alist $i] is not a legal action value"
      } else {
        set rval [expr $rval + [lindex $alist $i]]
      }
    } else {
      set rval [expr $rval + [expr $[lindex $alist $i]]]
    }
  }
  return $rval
}

proc severity_to_value { severity } {
  global INFO
  global WARNING
  global ERROR
  global FATAL

  switch "$severity" {
    "INFO"    { return $INFO }
    "OVM_INFO"    { return $INFO }
    "WARNING" { return $WARNING }
    "OVM_WARNING" { return $WARNING }
    "ERROR"   { return $ERROR }
    "OVM_ERROR"   { return $ERROR }
    "FATAL"   { return $FATAL }
    "OVM_FATAL"   { return $FATAL }
  }
  return "$severity"
}

proc value_to_verbosity { value } {
  global NONE
  global LOW
  global MEDIUM
  global HIGH
  global FULL 
  global DEBUG 

  if { $value == $NONE } { return "NONE" }
  if { $value == $LOW } { return "LOW" }
  if { $value == $MEDIUM } { return "MEDIUM" }
  if { $value == $HIGH } { return "HIGH" }
  if { $value == $FULL } { return "FULL" }
  if { $value == $DEBUG } { return "DEBUG" }
  return $value
}

proc is_verbosity_value { value } {
  global NONE
  global LOW
  global MEDIUM
  global HIGH
  global FULL 
  global DEBUG 
  set value [verbosity_to_value $value]
  if { ($value == $NONE)   || ($value == $LOW)  ||
       ($value == $MEDIUM) || ($value == $HIGH) ||
       ($value == $FULL)   || ($value == $DEBUG) } {
     return 1
  }
  return 0
}

proc value_to_severity { value } {
  global INFO
  global WARNING
  global ERROR
  global FATAL

  if { $value == $INFO }    { return "INFO" }
  if { $value == $WARNING } { return "WARNING" }
  if { $value == $ERROR }   { return "ERROR" }
  if { $value == $FATAL }   { return "FATAL" }
  return $value
}

proc is_severity_value { value } {
  global INFO
  global WARNING
  global ERROR
  global FATAL

  set value [severity_to_value $value]
  if { ($value == $INFO)  || ($value == $WARNING) ||
       ($value == $ERROR) || ($value == $FATAL) } { 
    return 1
  }
  return 0
}

proc value_to_style { value } {
  global SHORT
  global LONG
  global RAW

  if { $value == $SHORT } { return "SHORT" }
  if { $value == $LONG }  { return "LONG" }
  if { $value == $RAW }   { return "RAW" }
  return $value
}

proc is_style_value { value } {
  global RAW
  global SHORT
  global LONG

  set value [style_to_value $value]
  if { ($value == $SHORT) || ($value == $LONG) || ($value == $RAW) } { 
    return 1
  }
  return 0
}

proc value_to_actions { value } {
  global NO_ACTION
  global DISPLAY
  global LOG
  global COUNT
  global EXIT
  global CALL_HOOK
  global STOP

  set vlist [concat $NO_ACTION $DISPLAY $LOG $COUNT $EXIT $CALL_HOOK $STOP]
  set alist [concat NO_ACTION DISPLAY LOG COUNT EXIT CALL_HOOK STOP]

  set actions ""

  for {set i 0} {$i < [llength $vlist]} {incr i} {
    if { [expr ([lindex $vlist $i] & $value) != 0] } {
       if { $actions == "" } {
          set actions [lindex $alist $i]
       } else {
          set actions "$actions | [lindex $alist $i]"
       }
    }
  }
  return "$actions"
}

proc is_actions_value { actions } {
  global NO_ACTION
  global DISPLAY
  global LOG
  global COUNT
  global EXIT
  global CALL_HOOK
  global STOP

  if { [isnumber $actions] } {
   set actions [ value_to_actions $actions ]
  }
  if { $actions == "" } { return 0 }

  #remove any whitespace
  regsub -all {[ \t\n\b]} $actions {} actions
  #remove OVM
  regsub -all {OVM_} $actions {} actions
  #exit and finish are synonymous
  regsub -all {FINISH} $actions {EXIT} actions


  set alist [split $actions |]
  for {set i 0} {$i < [llength $alist]} {incr i} {
    if { [regexp NO_ACTION|DISPLAY|LOG|COUNT|EXIT|CALL_HOOK|STOP [lindex $alist $i] ] == 0 } {
      return 0
    }
  }
  return 1
}

proc do_command { args } {
  if { [catch { set r [eval $args] } e ] } {
    if { [regexp OBJACC $e] } {
       puts "ovm: *E,OVMACC: OVM commands require read/write access for the verilog functions which implement the commands"
    } else { 
      puts -nonewline "$e"
    }
    return "command failed"
  }
  return $r
}

proc help args {
  if { [llength $args] == 0 } {
    puts ""
    puts "OVM commands:"
    puts ""
    puts "ovm_component ovm_get   ovm_message ovm_phase   ovm_set     ovm_version"
    puts [ncsim_builtin_help]
    return;
  }
  foreach i $args {
    if { $i == "ovm_component" } {
      puts "ovm_component................Get information on OVM components"
      puts "    -list....................List all OVM components"
      puts "    -tops....................Print top level components"
      puts "    -describe <names>........Print one or more OVM component."
      puts "        <names>..............List of components to describe"
      puts "        -depth <depth>.......The depth of the component hierarchy"
      puts "                             to display (the default is 1). A depth"
      puts "                             of -1 recurses the full hierarchy"
    } elseif { $i == "ovm_get" } {
      puts "ovm_get <name> <field>........Get the value of a variable from a"
      puts "                              component. The component name can"
      puts "                              be a wildcarded name. The field"
      puts "                              must exist in the component."
    } elseif { $i == "ovm_message" } {
     puts "ovm_message...................Access the OVM messaging service"
     puts "    -set_handler_style <style> "
     puts "                              Set the style for the matching"
     puts "                              handler to use. Legal values are"
     puts "                              SHORT, LONG, RAW"
     puts "      -hierarchy <string>.......Specify the message handlers to set"
     puts "                              the style on. The full names of units"
     puts "                              are searched for a match. If no"
     puts "                              hierarchy is given then the global"
     puts "                              handler is set."
     puts "    -get_style <search criteria>"
     puts "                              Lists all style override requests that"
     puts "                              have been registered with the message"
     puts "                              service in the order they will be applied."
     puts "                              Legal search criteria are listed below."
     puts "    -set_style <search criteria> <style>"
     puts "                              Registers a style override request for the"
     puts "                              matching handler(s). Search criteria are"
     puts "                              listed below. Style is one of SHORT, LONG,"
     puts "                              or RAW. Legal search criteria are listed"
     puts "                              below."
     puts "       -remove................Removes the last registered override"
     puts "                              that exactly matches the given"
     puts "                              request."
     puts "    -set_handler_verbosity <verbosity>"
     puts "                              Set the verbosity for the matching"
     puts "                              handler to use. Legal values are"
     puts "                              NONE, LOW, MEDIUM, HIGH, FULL, DEBUG."
     puts "      -hierarchy <string>.....Specify the message handlers to get"
     puts "                              the style on. The full names of units"
     puts "                              are searched first for a match. If no"
     puts "                              hierarchy is given then the global"
     puts "                              handler style is retrieved."
     puts "    -get_verbosity <search criteria>"
     puts "                              Gets a list of verbosity override requests"
     puts "                              for the matching handler. Legal search"
     puts "                              criteria are listed below."
     puts "    -set_verbosity <search criteria> <vebosity>"
     puts "                              Registers a verbosity override request for"
     puts "                              the matching handler(s). Verbosity is one"
     puts "                              of NONE, LOW, MEDIUM, HIGH, FULL, DEBUG. Legal"
     puts "                              search criteria are listed below."
     puts "       -remove................Removes the last registered override"
     puts "                              that exactly matches the given"
     puts "                              request."
     puts "    -set_handler_severity.....Set the severity for the matching"
     puts "                              handler to use. Legal values are"
     puts "                              INFO, WARNING, ERROR, FATAL."
     puts "    -get_severity <search criteria>"
     puts "                              Gets a list of severity override requests"
     puts "                              for the matching handler. Legal search"
     puts "                              criteria are listed below."
     puts "    -set_severity <search criteria> <severity>"
     puts "                              Registers a severity override request for"
     puts "                              the matching handler to override the"
     puts "                              severity. Severity is one of INFO,"
     puts "                              WARNING, ERROR, FATAL. Legal search"
     puts "                              criteria are listed below."
     puts "       -remove................Removes the last registered override"
     puts "                              that exactly matches the given"
     puts "                              request."
     puts "    -set_handler_actions......Set the actions for the matching"
     puts "                              handler to use. Legal values are"
     puts "                              NO_ACTION, DISPLAY, LOG,"
     puts "                              COUNT, EXIT, CALL_HOOK, STOP,"
     puts "                              Actions may be ored togehter."
     puts "       -severity <severity>...Match the severity as well as the"
     puts "                              basic message search criteria."
     puts "    -get_actions <search criteria>"
     puts "                              Gets a list of action override requests"
     puts "                              for the matching handler. Legal search"
     puts "                              criteria are listed below."
     puts "    -set_actions <search criteria> <action> <severity>"
     puts "                              Registers an action override request for"
     puts "                              the matching handler. A search criteria"
     puts "                              is required. Action is one of NO_ACTION,"
     puts "                              DISPLAY, LOG, CALL_HOOK, COUNT, EXIT,"
     puts "                              STOP. Legal search criteria are listed"
     puts "                              below."
     puts "       -severity <severity>...A severity is required for each action"
     puts "                              override. The -severity is optional."
     puts "       -remove................Removes the last registered override"
     puts "                              that exactly matches the given"
     puts "                              request."
     puts "    \[search criteria\].........For commands which work on override"
     puts "                              requests (g/set_verbosity,g/set_actions,"
     puts "                              etc.), the legal search criteria are"
     puts "                              listed below. If a search criteria is not"
     puts "                              specified for a command that requires one,"
     puts "                              the global handler is chosen."
     puts "         -hierarchy <name>....Limit access to the specified"
     puts "                              hierarchical elements. Wildcards"
     puts "                              are allowed."
     puts "         -name <reporter>.....Limit access to the specified"
     puts "                              reporters"
     puts "         -scope <scope>.......Limit access to the specified"
     puts "                              declarative scopes for the messages"
     puts "         -file <file>.........Limit access to the specified"
     puts "                              files that the messages are emitted"
     puts "                              from"
     puts "         -line <line>.........Limit access to the specified"
     puts "                              lines that the messages are emitted"
     puts "                              from"
     puts "         -text <text>.........Limit access to the specified"
     puts "                              text string matching the message"
     puts "         -tag <tag>...........Limit access to the specified"
     puts "                              tag matching the message tag"
     puts ""
     puts "    Shortcut variants for the ovm_message command:"
     puts "       ovm_message <verbosity>|<severity>|<style>|<action>"
     puts "                              Set the global message handler using"
     puts "                              the provided value. This is equivalent to"
     puts "                              ovm_message -set_handler_verbosity <verbosity>"
     puts "                              as an example. Since all values are distinct"
     puts "                              user intent is inferred by the value."
     puts "       ovm_message <hierarchy> <verbosity>|<severity>|<style>|<action> [-remove]"
     puts "                              Set a message override using the provided"
     puts "                              value. This is equivalent to: ovm_message "
     puts "                              -hierarchy <hierarchy> -set_verbosity <verbosity>"
     puts "                              as an example."
    } elseif { $i == "ovm_phase" } {
      puts "ovm_phase <option>...........Access the phase interface for breaking on "
      puts "                             phases, or executing stop requests on phases."
      puts "    -delete..................Remove a previously set -stop_at break point."
      puts "    -get.....................Get the name of the current phase. This is the"
      puts "                             default option if no other options are specified."
      puts "    -run <phase name>........Run to the desired phase."
      puts "    -stop_at <options> <phase name> <stop options>"
      puts "                             Set a break point on the specified phase. By"
      puts "                             default, the break will occur at the start of"
      puts "                             the phase. A standard tcl break point (using the"
      puts "                             stop commmand) is issued. All options after the"
      puts "                             phase name are sent to the stop command. Use"
      puts "                             \"help stop\" for a list of options that can be used."
      puts "      -begin.................Set the callback for the beginning of the phase."
      puts "                             This is the default."
      puts "      -build_done............Sets a callback when the primary environment"
      puts "                             build out (from the run_test() command) is"
      puts "                             complete."
      puts "      -end...................Set the callback for the end of the phase."
      puts "    -stop_request............Execute a global stop request for the current"
      puts "                             phase."
    } elseif { $i == "ovm_set" } {
      puts "ovm_set <name> <field> <value>"
      puts "                             Set <field> for unit <name>."
      puts "    -config                  Apply the set to a configuration parameter. This"
      puts "                             means that the setting will not be applied until"
      puts "                             the specified component updates its configuration"
      puts "                             (which normally occurs during build()."
      puts "    -type int | string.......Specify the type of object to set." 
      puts "                             If type is not specified then if value "
      puts "                             is an integral value, int is assumed,"
      puts "                             otherwise string is assumed. For non-config sets"
      puts "                             the field must exist in the component."
    } elseif { $i == "ovm_version" } {
      puts "ovm_version..................Get the OVM library version."
    } else {
      puts [ncsim_builtin_help $i]
    }
  }
}

proc ovm_get args {
  set num [llength $args]
  if { $num < 2 && [lindex $args 0] != "-help" } {
    puts "ovm_get <name> <field>"
    return
  }
  if { $num < 2 && [lindex $args 0] == "-help" } {
    help ovm_get 
    return
  }

  set name [lindex $args 0]
  set field [lindex $args 1]

  for {set i 2} {$i < [llength $args]} {incr i} {
    set value [lindex $args $i]
    if { $value == "-help" } {
      help ovm_get 
      return
    } elseif { [string index $value 0] == "-" } {
      puts "ovm: *E,UNKOPT: unrecognized option for the ovm_get command ($value)."
      return
    } elseif { $value != "" } {
      puts "ovm: *E,UNKOPT: unrecognized option for the ovm_get command ($value)."
      return
    }
  }
  if { [regexp {[*?]} $field ] } {
    puts "ovm: *E,NOWLCD: Wildcard field name, $field, not allowed for ovm_get"
    return
  }

  set comps [ovm_component -describe $name -depth 0]
  if { [regexp {@[0-9]+} $comps comp] } {
    return [do_command value ${comp}.${field}]
  } else {
    puts "ovm: *E,NOMTCH: Did not match any components to $name"
  }
}
proc ovm_set args {
  set num [llength $args]
  if { $num < 3 && [lindex $args 0] != "-help" } {
    puts "ovm_set <name> <field> <value>"
    return
  }
  if { $num < 3 && [lindex $args 0] == "-help" } {
    help ovm_set 
    return
  }

  set name  -1
  set field -1
  set int 0 
  set str 0 
  set config 0
  set v 0

  
  for {set i 0} {$i < [llength $args]} {incr i} {
    set value [lindex $args $i]
    if { $value == "-help" } {
      help ovm_set 
      return
    } elseif { $value == "-config" } {
      set config 1
    } elseif { $value == "-type" } {
      incr i
      set value [lindex $args $i]
      if { $value == "int" } {
        set int 1
      } elseif { $value == "string" } {
        set str 1
      } else {
        puts "Error: illegal type [lindex $args $i] specifed with -type option"
      }
    } elseif { [string index $value 0] == "-" } {
      puts "ovm: *E,UNKOPT: unrecognized option for the ovm_set command ($value)."
      return
    } else {
      if { $name == -1 } { 
        set name $value 
      } elseif { $field == -1 } {
        set field $value
      } else {
        set v $value
      }
    }
  }
  if { ($name == -1)  || ($field == -1) } {
     puts "ovm: *E,ILLCL: ovm_set requires a unit and a field"
     return
  } 
  if { $int == 0 && $str == 0 } {
    if { [is_verbosity_value $v] } {
      set v [verbosity_to_value $v]
    } elseif { [is_severity_value $v] } {
      set v [severity_to_value $v]
    }
    if { [isnumber $v] } {
      set int 1
      set str 0
    } else {
      set int 0
      set str 1
    }
  }
  if { $int == 0 && $str == 0 } {
    puts "Error: no value given for setting field $field"
    return
  }
  if { $int == 1 && $config == 1} {
    call tcl_ovm_set \"$name\" \"$field\" $v $config
  } elseif { $config == 1} {
    call tcl_ovm_set_string \"$name\" \"$field\" \"$v\" $config
  } else {
    set comps [ovm_component -describe $name -depth 0]
    if { [regexp {@[0-9]+} $comps comp] } {
      foreach  i [split $comps] {
        if { [regexp {@[0-9]+} $i comp] } {
          if { $int == 1} {
            do_command deposit ${comp}.${field} $v
          } else {
            do_command deposit ${comp}.${field} \"$v\"
      }}}
    } else {
        puts "ovm: *E,NOMTCH: Did not match any components to $name"
    }
  }
}

proc ovm_component args {
  set depth "default"
  set ll   0
  set desc 0
  set tops  0
  set names [list]
  set scope [scope]
  if { [llength $args] == 0 } {
    puts "ovm_component <options>"
    return
  } 
  for {set i 0} {$i < [llength $args]} {incr i} {
    set value [lindex $args $i]
    if { $value == "-depth" } {
      incr i
      set depth [lindex $args $i] 
    } elseif { $value  == "-list" } {
      set ll 1
    } elseif { $value  == "-help" } {
      help ovm_component
      return
    } elseif { $value  == "-describe" } {
      set desc 1
    } elseif { $value  == "-tops" } {
      set tops 1
      set desc 1
    } elseif { [string index $value 0] == "-" } {
      puts "ovm: *E,UNKOPT: unrecognized option for the ovm_component command ($value)."
      return
    } else {
      lappend names $value
    }
  }
  if { ("$depth" == "default") && ($tops == 1)} {
    set depth 0
  } elseif {$depth == "default" } {
    set depth 1
  }
  if { $ll == 1 } { 
    call tcl_ovm_list_components 1
    set rval [ovm_get_result]
    scope -set $scope
    if { [llength $names] != 0 } {
      set l {}
      set rl [split $rval "\n"]
      set rl [lrange $rl 1 [ expr [llength $rl] -2] ]
      set nm  [join $names " "]
      foreach i $rl {
        foreach pattern $names {
          if [string match $pattern [lindex [split $i " "] 0] ] { lappend l $i }
      } }
      if { [llength $l] == 0 } {
        set rval "No ovm components match the input name(s): $nm" 
      } else {
        set match [join $l "\n"]
        set rval "List of ovm components matching the input name(s): $nm\n$match"
      }
    }
    return $rval
  } 
  if { $desc == 1 } {
    if { $tops == 1 } {
      call tcl_ovm_print_components $depth 0 1
      set rval [ovm_get_result]
      scope -set $scope
      return $rval
    } else {
      if { [llength $names] == 0 } {
        puts "ovm: *E,ILLOPT: the -describe option requires a component name"
      }
      set rval ""
      foreach name $names {
        call tcl_ovm_print_component \"$name\" $depth 1
        if { $rval != "" } { set rval "$rval\n" }
        set rval "${rval}[ovm_get_result]"
      }
      scope -set $scope
      return $rval
    }
  } elseif { [llength $names] != 0 } {
    puts "ovm: *E,NOACT: no action specified for the components \"$names\""
  } else {
    puts "ovm: *E,ILLOPT: illegal usage of the ovm_component command"
  }
}

proc do_value_check { value_type value_in prev_setting what} {
  global UNDEF
  global ANYSET

  if { $prev_setting != $UNDEF } {
    puts "ovm: *E,ILLARG: $value_type value [exec value_to_$value_type $prev_setting] is already set, $value_in is not allowed."
    return 0
  } else {
    set value [eval "${value_type}_to_value $value_in"]
    if { ! [isnumber $value] } {
      puts "ovm: *E,ILLVAL: illegal value $value_in used for setting ${value_type}."
      return 0
    } elseif {($what != $UNDEF) && ($what != $ANYSET)} {
      puts "ovm: *E,ILLARG: it is illegal to set a message action when a get has already been specified"
      return 0
    } 
  }
  return 1
}

proc ovm_message args {
  global UNDEF
  global SET_VERBOSITY
  global GET_VERBOSITY
  global SET_ACTIONS
  global GET_ACTIONS
  global SET_STYLE
  global GET_STYLE
  global SET_SEVERITY
  global GET_SEVERITY
  global ANYSET

  #### These are used for the override versions, not the 
  #### handler versions.
  set hierarchy $UNDEF 
  set scope     "*"
  set file      "*"
  set line      $UNDEF
  set textval   "*"
  set tag       ""
  set remove    $UNDEF

  #### For handler versions. If handler_hier is empty string then
  #### means to use global.
  set handler_hier ""

  set argvalue ""
  set value    $UNDEF
  set what     $UNDEF
  set handler  $UNDEF

  set verbosity_value $UNDEF
  set severity_value  $UNDEF
  set actions_value   $UNDEF
  set style_value     $UNDEF
  set actions_sev      $UNDEF

  for {set i 0} {$i < [llength $args]} {incr i} {
    set argvalue [lindex $args $i]
    if { $argvalue  == "-help" } {
      help ovm_message
      return
    } elseif { $argvalue == "-hierarchy" } {
      incr i
      set hierarchy [lindex $args $i]
    } elseif { $argvalue == "-scope" } {
      incr i
      set scope [lindex $args $i]
    } elseif { $argvalue == "-file" } {
      incr i
      set file [lindex $args $i]
    } elseif { $argvalue == "-line" } {
      incr i
      set line [lindex $args $i]
    } elseif { $argvalue == "-text" } {
      incr i
      set textval [lindex $args $i]
    } elseif { $argvalue == "-tag" } {
      incr i
      set tag [lindex $args $i]
    } elseif { $argvalue == "-remove" } {
      set remove 1
    } elseif {$argvalue == "-get_verbosity" } {
      if {$what != $UNDEF} {
        puts "ovm: *E,ILLARG: it is illegal to use $argvalue with any other -get or -set option"
        return
      }
      set what $GET_VERBOSITY
    } elseif { $argvalue == "-set_handler_verbosity" } {
      incr i
      set argvalue [lindex $args $i]
      if { [do_value_check "verbosity" $argvalue $verbosity_value $what] } {
        set verbosity_value [verbosity_to_value $argvalue]
        if { $verbosity_value == -1 } {
          puts "ovm: *E,ILLVAL: $argvalue is an invalid value for -set_handler_verbosity <value>"
          return
        }
        set handler 1
      } else { return }
      set what $ANYSET
    } elseif { $argvalue == "-set_verbosity" } {
      incr i
      set argvalue [lindex $args $i]
      if { [do_value_check "verbosity" $argvalue $verbosity_value $what] } {
        set verbosity_value [verbosity_to_value $argvalue]
        if { $verbosity_value == -1 } {
          puts "ovm: *E,ILLVAL: $argvalue is an invalid value for -set_verbosity <value>"
          return
        }
        set what $ANYSET
        set handler 0
      } else { return }
    } elseif { $argvalue == "-get_actions" } {
      if {$what != $UNDEF} {
        puts "ovm: *E,ILLARG: it is illegal to use $argvalue with any other -get or -set option"
        return
      }
      set what $GET_ACTIONS
    } elseif { $argvalue == "-set_handler_actions" } {
      incr i
      set argvalue [lindex $args $i]
      if { [do_value_check "actions" $argvalue $actions_value $what] } {
        set actions_value [actions_to_value $argvalue]
        set what $ANYSET
        set handler 1
      } else { 
        return 
      }
    } elseif { $argvalue == "-set_actions" } {
      incr i
      set argvalue [lindex $args $i]
      if { [do_value_check "actions" $argvalue $actions_value $what] } {
        set actions_value [actions_to_value $argvalue]
        set what $ANYSET
        set handler 0
      } else { return }
    } elseif { $argvalue == "-severity" } {
      incr i
      set actions_sev [severity_to_value [lindex $args $i]]
      if { ! [is_severity_value $actions_sev ] } {
        puts "ovm: *E,ILLVAL: [lindex $args $i] is not a legal severity value"
        return
      }
    } elseif { $argvalue == "-get_severity" } {
      if {$what != $UNDEF} {
        puts "ovm: *E,ILLARG: it is illegal to use $argvalue with any other -get or -set option"
        return
      }
      set what $GET_SEVERITY
    } elseif { $argvalue == "-set_handler_severity" } {
      incr i
      set argvalue [lindex $args $i]
      if { [do_value_check "severity" $argvalue $severity_value $what] } {
        set severity_value [severity_to_value $argvalue]
        set what $ANYSET
        set handler 1
      } else { return }
    } elseif { $argvalue == "-set_severity" } {
      incr i
      set argvalue [lindex $args $i]
      if { [do_value_check "severity" $argvalue $severity_value $what] } {
        set severity_value [severity_to_value $argvalue]
        set what $ANYSET
        set handler 0
      } else { return }
    } elseif { $argvalue == "-get_style"} {
      if {$what != $UNDEF} {
        puts "ovm: *E,ILLARG: it is illegal to use $argvalue with any other -get or -set option"
        return
      }
      set what $GET_STYLE
    } elseif { $argvalue == "-set_handler_style" } {
      incr i
      set argvalue [lindex $args $i]
      if { [do_value_check "style" $argvalue $style_value $what] } {
        set style_value [style_to_style $argvalue]
        set what $ANYSET
        set handler 1
      } else { return }
    } elseif { $argvalue == "-set_style" } {
      incr i
      set argvalue [lindex $args $i]
      if { [do_value_check "style" $argvalue $style_value $what] } {
        set style_value [style_to_value $argvalue]
        set what $ANYSET
        set handler 0
      } else { return }
    } elseif { [string index $argvalue 0] == "-" } {
      puts "ovm: *E,UNKOPT: unrecognized option for the ovm_message command ($argvalue)."
      return
    } else {
      if { [is_verbosity_value [verbosity_to_value $argvalue] ] } {
        set verbosity_value [verbosity_to_value $argvalue]
        set what $ANYSET
      } elseif { [is_severity_value [severity_to_value $argvalue] ] } {
        set severity_value [severity_to_value $argvalue]
        set what $ANYSET
      } elseif { [is_actions_value [actions_to_value $argvalue] ] } {
        set actions_value [actions_to_value $argvalue]
        set what $ANYSET
      } elseif { [is_style_value [style_to_value $argvalue] ] } {
        set style_value [style_to_value $argvalue]
        set what $ANYSET
      } elseif { [isnumber $argvalue] } {
          puts "ovm: *E,ILLOPT: Illegal value $argvalue. Cannot determine the operation to use."
      } else {
        if { ($hierarchy != $UNDEF) } {
          puts "ovm: *E,ILLOPT: Illegal argument $argvalue passed to ovm_message."
        } else {
          set hierarchy $argvalue
        }
      }
    }
  }
  if { [llength $args] == 0 } {
     puts "ovm_message <filter> <access option>"
     return
  } 

  ### if using the override version and the hiearchy is not given, need
  ### to set it.
  if { $handler == $UNDEF } { 
    set handler 0
  }
  if { $remove == $UNDEF } {
    set remove 0
  }
  if { ($handler == 0) && ($hierarchy == $UNDEF) } {
    set hierarchy "*"
  } elseif { ($handler == 1) && ($hierarchy != $UNDEF)} {
    set handler_hier $hierarchy
  } elseif { ($handler == 1) && ($hierarchy == $UNDEF) } {
    set handler_hier ""
  }
  if { ($actions_value != $UNDEF) && ($actions_sev == $UNDEF) } {
    set actions_sev $severity_value
    set severity_value $UNDEF
    if { $actions_sev == $UNDEF } {
      puts "ovm: *E,ILLOPT: When setting an action, a severity must be supplied using the -severity option"
      return
    }
  }
  if { ($handler == 1) && ($what == $ANYSET) } {
    ### Do sets for a given handler
    if { $verbosity_value != $UNDEF } {
      tcl_set_handler_message $SET_VERBOSITY "$handler_hier" $verbosity_value
    }
    if { $severity_value != $UNDEF } {
      tcl_set_handler_message $SET_SEVERITY "$handler_hier" $severity_value
    }
    if { $actions_value != $UNDEF } {
      tcl_set_handler_message $SET_ACTIONS "$handler_hier" $actions_value $actions_sev
    }
    if { $style_value != $UNDEF } {
      tcl_set_handler_message $SET_STYLE "$handler_hier" $style_value
    }
  } elseif { $what == $ANYSET } {
    ### Do set override
    if { $verbosity_value != $UNDEF } {
      tcl_set_message $SET_VERBOSITY $hierarchy $scope $file $line $textval $tag $remove $verbosity_value
    }
    if { $severity_value != $UNDEF } {
      tcl_set_message $SET_SEVERITY $hierarchy $scope $file $line $textval $tag $remove $severity_value
    }
    if { $actions_value != $UNDEF } {
      tcl_set_message $SET_ACTIONS $hierarchy $scope $file $line $textval $tag $remove $actions_value $actions_sev
    }
    if { $style_value != $UNDEF } {
      tcl_set_message $SET_STYLE $hierarchy $scope $file $line $textval $tag $remove $style_value
    }
  } else {
    return [tcl_get_message $what]
  }
}

set all_breaks("empty") 0
set break_by_name("empty") 0

proc remove_break {b} {
  global break_by_name
  global all_breaks

  if {[info exists break_by_name($b)] == 0} {
    return 0
  }
  unset all_breaks("$break_by_name($b)")
  unset break_by_name($b)
  return 1
}

proc ovm_phase args {
  global UNDEF
  global all_breaks
  global break_by_name

#  set break_phase $UNDEF
  set break_phase $UNDEF
  set run_phase $UNDEF
  set pre 1
  set get $UNDEF
  set stop_req $UNDEF
  set stop_options $UNDEF
  set ph_cmd ""

  if { [llength $args] == 0 } { set get 1 }
  for {set i 0} {$i < [llength $args]} {incr i} {
    set argvalue [lindex $args $i]
    if { $argvalue  == "-help" } {
      help ovm_phase
      return
    } elseif { $argvalue == "-delete" } {
      incr i
      set argvalue [lindex $args $i]
      if { [remove_break $argvalue] == 0 } {
        puts "ovm: *E,ILLBRK: break point \"$argvalue\" is not valid."
      }
      return
    } elseif { $argvalue == "-stop_at" } {
      incr i
      set argvalue [lindex $args $i]
      if { $argvalue == "-begin" } {
        set pre 1
      } elseif { $argvalue == "-end" } {
        set pre 0
      } elseif { $argvalue == "-build_done" } {
        set break_phase "ovm_build_complete"
      } elseif { [string index $argvalue 0] == "-" } {
        puts "ovm: *E,UNKOPT: unrecognized option for the -stop_at option ($argvalue)."
        return
      } else {
        set break_phase $argvalue
      }
      if { $break_phase == $UNDEF } {
        incr i
        set break_phase [lindex $args $i]
      }
      incr i
      while { $i < [llength $args] } {
        if { $stop_options == -1 } { set stop_options ""}
        set stop_options "$stop_options \{[lindex $args $i]\}"
        incr i
      }
    } elseif { $argvalue == "-get" } {
      set get 1
    } elseif { $argvalue == "-run" } {
      incr i
      set run_phase [lindex $args $i]
    } elseif { ($argvalue == "-stop_request") || ($argvalue == "-global_stop_request") } {
      set stop_req 1
    } else {
      puts "ovm: *E,UNKOPT: unrecognized option for the ovm_phase command ($argvalue)."
      return
    }
  }
  if { (($get != $UNDEF) && (($break_phase != $UNDEF) || ($run_phase != $UNDEF)) ) ||
       (($get != $UNDEF) && (($stop_req != $UNDEF) || ($run_phase != $UNDEF)) ) ||
       (($break_phase != $UNDEF) && (($stop_req != $UNDEF) || ($run_phase != $UNDEF))) } {
    puts "ovm: *E,ILLARG: Only one operation may be specified: set break, get phase, set stop request, or run phase"
    return
  }
  if { $get == 1 } {
    set scope [scope]
    call tcl_ovm_get_phase
    set rval [ovm_get_result]
    scope -set $scope
    return $rval
  } elseif { $stop_req == 1 } {
    task cdns_tcl_global_stop_request
  } elseif { $break_phase != $UNDEF } {
    set scope [scope]
    call ovm_set_debug_scope
    if { $break_phase == "ovm_build_complete" } {
      set ph_cmd "$ph_cmd -build_done"
      set stop_cmd "stop -object ovm_build_complete"
      if {$stop_options != $UNDEF} {
        set stop_cmd "$stop_cmd $stop_options"
        set ph_cmd "$ph_cmd $stop_options"
      }
    } else  {
      set stop_cmd "stop -condition \{\#ovm_break_phase == \"$break_phase\" && \#ovm_phase_is_start == $pre\}"
      if {$pre} { set ph_cmd "$ph_cmd -stop_at $break_phase -begin" } else { set ph_cmd "$ph_cmd -stop_at $break_phase -end" }
      if {$stop_options != $UNDEF} {
        set stop_cmd "$stop_cmd $stop_options"
        set ph_cmd "$ph_cmd $stop_options"
      } 
    }
    if { [info exists all_breaks("$ph_cmd")] } {
      scope -set $scope
      return "Stop $all_breaks(\"$ph_cmd\") already exists"
    }
    set tmp [split [eval $stop_cmd] " "]
    set tmp [lindex $tmp 2]
    set tmp [lindex [split $tmp "\n"] 0]
    set all_breaks("$ph_cmd") $tmp
    set break_by_name($tmp) "$ph_cmd"
    scope -set $scope
    return "Created stop $tmp"
  } elseif { $run_phase != $UNDEF } {
    call tcl_ovm_global_run_phase \"$run_phase\" 
  }
}

### For setting an override request. The sev input only applies if value_type 
### is SET_ACTIONS
proc tcl_set_message { value_type hier scope file line textval tag remove value {sev 0} } {
  ## strings: hier scope file textval tag
  ## ints: value_type line value sev
  ## bits: remove
  call tcl_ovm_set_message $value_type \"$hier\" \"$scope\" \"$file\" $line \"$textval\" \"$tag\" $remove $value $sev
}

### For setting a specific object. If hier is "" then the request is for the global 
### handler. The sev input only applies if value_type is SET_ACTIONS
proc tcl_set_handler_message { value_type hier value {sev 0} } {
  ## strings: hier 
  ## ints: value_type value sev
  call tcl_ovm_set_handler_message $value_type \"$hier\" $value $sev
}

### For getting rules
proc tcl_get_message { value_type } {
  ## ints: value_type 
  global GET_VERBOSITY
  global GET_SEVERITY
  global GET_STYLE
  global GET_ACTIONS
  if { ($value_type == $GET_VERBOSITY) || ($value_type == $GET_STYLE) ||
       ($value_type == $GET_SEVERITY) || ($value_type == $GET_ACTIONS) } {
    set scope [scope]
    call tcl_ovm_get_message $value_type 
    set rval [ovm_get_result]
    scope -set $scope
    return $rval
  } 
  puts "ovm: *E,ILLARG: Illegal value $value_type supplied to tcl_get_message"
}


### Tcl access to the ovm versoin
proc ovm_version { } {
  set scope [scope]
  call tcl_ovm_version
  set rval [ovm_get_result]
  scope -set $scope
  return $rval
}

