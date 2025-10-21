
global env

if {[info exists env(DUMPDB)]} {
  set DB_EN $env(DUMPDB)
} else {
  set DB_EN 0
}
puts "DB_EN=$DB_EN"


proc create_db {} {
  set assert_1164_warnings no
  database -open harness.shm -into harness.shm -event -default -compress
  probe -create -shm harness -all -variables -database harness.shm -depth all -memories
}


if {$DB_EN == 1} {
  create_db
}

run
