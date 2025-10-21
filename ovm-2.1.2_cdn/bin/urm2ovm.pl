################################################################################
#
# urm2ovm - URM to OVM converter  (c) 2006-07 Cadence Design Systems, Inc.
#
# Type urm2ovm -help 
#
################################################################################

package urm2ovm;

#use strict;
require 5.005;

use File::Basename;


my $R = 'r'; my $U = 'u'; my $N = 'n';
my $Q = 'q'; $U = 'u'; my $I = 'i'; my $E = 'e'; my $T = 't';

my $version_file = dirname($0)."/svpp_version.pl";
do $version_file;

### Globals
my @files_G = ();
my @copy_files_G = ();
my @dirs_G = ();

my %type_map = ();

my $copyright_G   = "(c) Copyright 2006-2007 Cadence Design Systems, Inc.";
my $toolname_G    = "urm2ovm";
my $version_G     = "$SVPP_KIT_VERSION";

if($version_G eq "") { $version_G = "<unknown>"; }

### Stats
my $mod_G = 0;
my $file_mod_G = 0;
my $warn_G = 0;
my $error_G = 0;

### Command-line arguments
my $HELP_ARG      = 0;
my @EXT_ARG_LIST  = (".sv", ".svh");
my @EXT_ARG       = ();
my $LOGFILE_ARG   = "urm2ovm.log";
my $MODNAME_ARG   = 0;
my $NOMODNAME_ARG = 0;
my $OUTDIR_ARG    = "";
my $RECURSE_ARG   = 0;
my $NORECURSE_ARG = 0;
my $VERBOSE_ARG   = 0;
my $VERSION_ARG   = 0;
my $ROOT_DIR      = "";
my $OUTDIR        = "";

### URM globals that need to convert to ovm globals by prepending OVM_
my $urm_global_lc_G = "print_topology|enable_print_topology" .
                      "|is_match".
                      "|string_to_bits|bits_to_string".
                      "|default_(comparer|recorder|packer)".
                      "|default_(line_|tree_|table_)?printer".
                      "|bitstream_t|bytestream_t";
my $urm_global_uc_G = "NONE|LOW|MEDIUM|HIGH|FULL" .
                      "|STREAMBITS" .
# Don't need to do action or severity since the conversion of URM to OVM catches
# these.
#                      "|NO_ACTION|DISPLAY|LOG|COUNT|EXIT|CALL_HOOK|STOP" .
#                      "|INFO|MESSAGE|WARNING|ERROR|FATAL" .
                      "|NONE|LOW|MEDIUM|HIGH|FULL" .
                      "|RADIX|BIN|DEC|UNSIGNED|OCT|HEX|STRING|TIME|ENUM|NORADIX" .
                      "|DEFAULT_POLICY|DEEP|SHALLOW|REFERENCE|DEFAULT|ALL_ON|FLAGS_ON" .
                      "|COPY|NOCOPY|COMPARE|NOCOMPARE|PRINT|NOPRINT" .
                      "|RECORD|NORECORD|PACK|NOPACK|PHYSICAL|ABSTRACT|READONLY" .
                      "|NODEFPRINT" .
                      "|ACTIVE|PASSIVE|UNDEF" ;

# These message macros need to stay as urm. However, the generic urm->ovm will
# convert them. So, we need to convert back.

my $urm_message_macros = "`ovm_(" .
                         "(data|code|flow)_debug|info\d" .
                         "|((info|warning|error|fatal)(_id)?)" .
                         ")";

#-------------------------------------------------------------------------------
#
# MAIN PROGAM
#
#-------------------------------------------------------------------------------

&process_command_line_options;
&process_command_line_files;
if($file_mod_G == 0)
{
  print_to_log("No files were modified\n");
}
else
{
  print_to_log("$file_mod_G files were modified: $mod_G changes made\n");
}

#-------------------------------------------------------------------------------
#
# Write to log
#
#-------------------------------------------------------------------------------

sub print_to_log
{
  my $msg = shift;
  print STDOUT "$msg";
  print LOGFILE "$msg";
}

#-------------------------------------------------------------------------------
#
# process_command_line_options
#
#-------------------------------------------------------------------------------

sub process_command_line_options
{
  
  use Getopt::Long;
  #Getopt::Long::Configure("debug");

  $banner_G = "$toolname_G: $version_G: $copyright_G";
  
  &dump_synopsis(\*STDERR,$banner_G) if @ARGV <= 0;

  use Pod::Usage;
  
  my $result = GetOptions(
  
    'help'       => \$HELP_ARG,
    'ext=s'      => \@EXT_ARG,
    'log=s'      => \$LOGFILE_ARG,
    'modname'    => \$MODNAME_ARG,
    'nomodname'  => \$NOMODNAME_ARG,
    'outdir=s'   => \$OUTDIR_ARG,
    'norecurse'  => \$NORECURSE_ARG,
    'recurse'    => \$RECURSE_ARG,
    'verbose'    => \$VERBOSE_ARG,
    'version'    => \$VERSION_ARG,
  ) or pod2usage(2);

  exit if (!$result);

  if ($HELP_ARG != 0)
  {
    &dump_synopsis(\*STDOUT,$banner_G);
  }
  if ($VERSION_ARG != 0)
  {
    print STDOUT "TOOL:\t$toolname_G\t$version_G\n\n"; 
    exit 0;
  }

  if ($MODNAME_ARG == 1 && $NOMODNAME_ARG == 1)
  {
    $MODNAME_ARG = 1;
  }
  elsif($MODNAME_ARG == 0 && $NOMODNAME_ARG == 0)
  {
    $MODNAME_ARG = 1;
  }

  open (LOGFILE, ">$LOGFILE_ARG") ||
       die "Can't open logfile, $LOGFILE_ARG";

  print_to_log "$banner_G\n";

  if ($NORECURSE_ARG == 0 && $RECURSE_ARG == 0) 
  {
    $RECURSE_ARG = 1;
  }
  push (@EXT_ARG_LIST, split ":", (join ":", @EXT_ARG));
  foreach $file (@ARGV)
  {
    if (-f $file) { push(@files_G, $file); }
    elsif(-d $file) { push(@dirs_G, $file); }
    else {print_to_log "$toolname_G: *E,BDFIL: file/directory \"$file\" not found\n\n"; }
  }

}


#-------------------------------------------------------------------------------
#
# process_command_line_files
#
# Call process_file for each command-line file, after verifying all of them exist
#
# Args   : none
# Globals: $files_G
# Output : updates each entry in files_G with full filespec
# Return : none
# Persistent Allocations: none
#-------------------------------------------------------------------------------

sub create_file_name
{
  ### $f is the original file name, it may be a full or relative path
  ### $dir is the output directory. The full output is $dir/$f, but the 
  ### common part of the name must be stripped first.
  my $f = shift;
  my $dir = shift;
  my $fdir;

  if($MODNAME_ARG != 0)
  {
    $f =~ s{driver}{sequencer}g;
    $f =~ s{bfm}{driver}g;
  }
  if($dir ne "")
  { 
    $fdir = `cd \`dirname $f\`; pwd`; chomp $fdir;
    $f = $fdir . "/" . `basename $f`; chomp $f;

    $f =~ s{^$ROOT_DIR}{};
    $fdir = `dirname $dir/$f`; chomp $fdir;
    system ("mkdir -p $fdir");
    if(! -d $fdir)
    {
      print_to_log "$toolname_G: *E,DIRFLD: unable to created output directory $fdir, check permissions\n\n";
      return;
    }
    $dir =~ s{\/$}{}; #remove extraneous trailing / if it exists
    return "$dir/$f"; 
  }
  return $f;
}

sub process_command_line_files
{
  ### no args

  my $file;
  my $outdir;
  my $outfile;
  my $fcnt = $#files_G+1;
  my $gui = "NO_GUI_PRINTER_DEFINED";

  ### now go ahead an parse the files
  foreach $file (@files_G)
  {
    $outfile = "$file.ovm";
    process_file($file, create_file_name($file));
  }

  ### process the directories
  foreach $dir (@dirs_G)
  {
    @files_G = ();
    @copy_files_G = ();
    if($OUTDIR_ARG eq "")
    {
      $outdir = `cd $dir; pwd`; chomp $outdir;
      $outdir =~ s{/([^/]*)$}{/ovm_$1};
    }
    else
    {
      $outdir = $OUTDIR_ARG;
    } 
    system ("mkdir -p $outdir");
    if(! -d $outdir)
    {
      print_to_log "$toolname_G: *E,DIRFLD: unable to created output directory $outdir, check permissions\n\n";
      return;
    }
    $ROOT_DIR = `cd $dir; pwd`; chomp $ROOT_DIR;
    $OUTDIR = $outdir;
    process_directory($dir);
    $fcnt += $#files_G+1;
    foreach $file (@files_G)
    {
      my $fdir;
      process_file($file, create_file_name($file, $outdir));
    }
    foreach $file (@copy_files_G)
    {
      my $cf = create_file_name($file, $outdir);
      system ("cp -r $file $cf");
    }
  }

  if ($fcnt <= 0) {
    print_to_log "$toolname_G: *E,FILEMIS: no urm source files found to process\n\n";
    exit -1;
  }
  else
  {
    print_to_log "$toolname_G: *N,FILPRC: $fcnt urm source files were processed\n\n";
  }

}


#-------------------------------------------------------------------------------
#
# process_directory
#
# Convert the files in the specified directory from URM to OVM
#
# Args   : $dir, the directory is guaranteed to exist.
# Globals: $files_G, the list of files to process 
# Output : All SystemVerilog files are added to the list of files to process.
# Return : none
# Persistent Allocations: none
#-------------------------------------------------------------------------------


sub process_directory
{
  my $dir = shift;
  my @dirs = ();
  my $ext = join("|", @EXT_ARG_LIST);

  $ext = "($ext)\$";
  $ext =~ s/\./\\./;

  if($VERBOSE_ARG == 1)
  {
    print_to_log "Searching directory: \"$dir\" ...\n";
  }
  foreach $file (glob ("$dir/*"))
  {
    if(! -l $file)
    {
      if(-d $file && $RECURSE_ARG)
      {
        process_directory("$file");
      }
      elsif(-f $file)
      {
        if($file =~ $ext) { push(@files_G, $file); }      
        else { push(@copy_files_G, $file); }
      }
    }
  }
}

#-------------------------------------------------------------------------------
#
# process_file
#
# Convert the specified file from URM to OVM
#
# Args   : $file, the file is guaranteed to exist. $outfile is the output file.
# Output : $outfile is $file with all urm2ovm conversions done on it.
# Return : none
# Persistent Allocations: none
#-------------------------------------------------------------------------------


sub process_file
{
  ### no args

  my $file = shift;
  my $line = 1;
  my $outfile = shift;
  my $cnt = 0;
  my $pcnt = 0;
  my $curr;
  my $opt = "opt";
  my $lineorig;
  my $is_virt_seq = 0;
  my $in_seq_sub = 0;
  my $in_build = 0;
  my $build_found = 0;
  my $build_imp = "";
  my $post_build = "";
  my $mm = "";

  my $modfile;

  my $ifile = `cd \`dirname $file\`; pwd`; chomp $ifile; $ifile .= "/" . `basename $file`; chomp $ifile;
  my $ofile = `cd \`dirname $outfile\`; pwd`; chomp $ofile; $ofile .= "/" . `basename $outfile`; chomp $ofile;

  if($ifile eq $ofile)
  {
    $outfile = "$outfile.ovm";
  }
  
  $. = 0;
  open (INFILE, "$file") ||
       die "Can't open file, $file";

  open (OUTFILE, ">$outfile") ||
       die "Can't open file, $outfile";

  print_to_log "Processing file: \"$file\" ...\n" if ($VERBOSE_ARG != 0);

  while ($line=<INFILE>) {
    $lineorig = $line;

    if($line =~ /set_config_string\b[^;]+$/)
    {
      $mm = $line;
    }
    elsif($mm ne "" && $mm !~ /;/)
    {
      $mm .= $line;
      if($mm =~ /;/) 
      { 
         $line = $mm; 
         $mm = ""; 
      }
    }
  if($mm eq "")
  {
    #Set up virtual sequencer changes
    if($line =~ /class\s+(\w+)\s+extends\s*\w+_virtual_(driver|sequencer)/)
    {
       print_to_log "$toolname_G: *N,VSEQIF: Note that for virtual sequencers in OVM, all subsequncers must be manually connected using add_seq_cons_if() method in the build() method of the virtual sequencer. Attempting to make these connections: $file ($.)\n\n";
       $is_virt_seq = 1;
    }
    if($is_virt_seq == 1 && $line =~ /function\s+void\s+set_sub_drivers\s*\(/)
    {
      $in_seq_sub = 1;
      $line = "";
    }
    if($line =~ /function\s+void\s+build\s*\(/)
    {
      if($is_virt_seq == 1)
      {
        $line = "";
        $build_found = 1;
      }
      $in_build = 1;
      $post_build = "";
    }
    if($line =~ /\bendfunction\b/)
    {
      if($in_seq_sub == 1 || ($in_build == 1 && $is_virt_seq == 1)) { $line = ""; }
      else { $line = $post_build . $line; }
      $in_seq_sub = 0;
      $in_build = 0;
    }
    if($is_virt_seq && $line =~ /(\s*)\bendclass\b/)
    {
      $is_virt_seq = 0;
      $in_build = 0;
      $in_seq_sub = 0;
      if($build_found == 0) { $build_imp = "    super.build();\n$build_imp"; }
      $build_found = 0;
      $line = "$1  function void build();\n$build_imp$1  endfunction\n$line";
    }
    if($in_seq_sub == 1)
    {
       if($line =~ /\$cast\s*\(\s*\w+\s*,\s*get_sub_driver\s*\(\s*(\"\w+\")/)
       {
          $build_imp .= "    add_seq_cons_if($1);\n";
       }
       else
       {
          $build_imp .= "$line";
       }
       $line = "";
    }
    if($line =~ m/set_config_string\s*\(\s*\"([^"]+)\"\s*,\s*\"sub_drivers\[([^\]]+)\]\"[^"]+"([^"]+)\"/)
    {
      $vseq = $1;
      $sub_seq_nm = $2;
      $sub_seq_act = $3;
      if($vseq =~ s/[*?]//g)
      {
        print_to_log "$toolname_G: *W,WLDCRD: A wildcard was found in the name of the virtual driver ".
            "The translation to OVM may not be correct: $file ($.)\n\n";
      }
      $sub_seq_act =~ s/^\.//;
      $post_build .= "    $vseq.seq_cons_if[\"$sub_seq_nm\"].connect_if($sub_seq_act.seq_prod_if);\n";
      $line = "/*** $line ***/\n";
    }

    #Get type/identifier information needed for certain mappings.
    if($line =~ /\s*(rand)?\s*(local|protected|static)?\s*(\w+((\s*#\s*\(.*\))?))(([,\s]+\w+)+)(\s*=.*)?;/)
    {
      my $id = $3;
      my $fields = $6;
      if($id !~ /typedef|class|return|endclass|module|interface|function/)
      {
        $fields =~ s/\s//g;
        foreach $field (split (",", $fields))
        { 
          $type_map{$field} = $id;
        }
      }
    }

    #Warn for deprecated features
   if($line =~ /(.*)`urm_field_int\s*\(\s*(\w+)\s*,\s*(.*ENUM.*)\)/) {
      my $pre = $1;
      my $field = $2;
      my $flags = $3;
      $flags =~ s/[|+]?\s*ENUM//;
      $flags =~ s/^\s*[|+]//;
      if($flags !~ /\w/) { $flags = "OVM_ALL_ON"; }

      if($type_map{$field} ne "") {
        $line = "${pre}\`urm_field_enum($type_map{$field},$field,$flags)\n";
      }
     
#        print_to_log "$toolname_G: *W,DEPFET: use of ENUM radix is deprectated in OVM, ".
#             "use `ovm_field_enum(ENUM_TYPE, FIELD, FLAGS) instead: $file ($.)\n\n";
#print "TYPE FOR \"$id\" IS: \"$type_map{$id}\"\n";
    }

    #Make header file / package changes
    $cnt += $line =~ s{urm.svh}{ovm.svh};
    $cnt += $line =~ s{tlm.svh}{ovm.svh};
    $cnt += $line =~ s{urm_meth.svh}{ovm.svh};
    $cnt += $line =~ s{urm_defines.svh}{ovm_macros.svh};
    $cnt += $line =~ s{urm_resetall.svh}{macros/ovm_undefineall.svh};
#    $cnt += $line =~ s{tlm.svh}{tlm/tlm.svh};
#    $cnt += $line =~ s{urm_meth.svh}{methodology/methodology.svh};
    $cnt += $line =~ s{\burm(_util_pkg)?::}{ovm_pkg::};

    #For MB, remove the `DEST in messages
    $cnt += $line =~ s{`URM_DEST\s*\,}{};
    $cnt += $line =~ s{\bmessage_verbosity_e\b}{ovm_verbosity}g;
    $cnt += $line =~ s{\bcheck_severity_e\b}{ovm_severity_type}g;
    $cnt += $line =~ s{\bMSG_TEXT_SIZE\b}{OVM_LARGE_STRING}g;
    $cnt += $line =~ s{\bURM_NAME_STRING_SIZE\b}{OVM_LARGE_STRING}g;

    #Messaging changes
    $cnt += $line =~ s{\bDEBUG\b}{OVM_DEBUG}g;
    $cnt += $line =~ s{\bURM_STYLE}{OVM_URM_STYLE}g;
    $cnt += $line =~ s{\burm_message_handler}{ovm_urm_report_server}g;
 
    #global name changes for driver/bfm to sequencer/driver
    my $inc_drv = $line =~ /`include\s+\".*(driver|bfm).*\"/;
    if(($MODNAME_ARG != 0) || ($inc_drv == 0))
    {
      $line =~ s{(\b|_)seq_drv(\b|_)}{$1driver$2}g; #seq_drv is a common alias for driver
      $cnt += $line =~ s{driver}{sequencer}g;
      $cnt += $line =~ s{DRIVER}{SEQUENCER}g;
      $cnt += $line =~ s{urm_driver}{ovm_sequencer}g;
      $cnt += $line =~ s{urm_virtual_driver}{ovm_virtual_sequencer}g;
      $cnt += $line =~ s{bfm}{driver}g;
      $cnt += $line =~ s{BFM}{DRIVER}g;
      $cnt += $line =~ s{urm_bfm}{ovm_driver}g;
    }

    #Make type changes
    $cnt += $line =~ s{urm_void}{ovm_void}g;
    $cnt += $line =~ s{urm_object}{ovm_object}g;
    $cnt += $line =~ s{urm_named_object}{ovm_component}g;
    $cnt += $line =~ s{urm_unit_base}{ovm_component}g;
    $cnt += $line =~ s{extends urm_unit}{extends ovm_threaded_component}g;
    $cnt += $line =~ s{urm_unit}{ovm_component}g;
    $cnt += $line =~ s{urm_transaction}{ovm_transaction}g;
    $cnt += $line =~ s{urm_bus_monitor}{ovm_monitor}g;
    $cnt += $line =~ s{\bactive_passive_e(num)?\b}{ovm_active_passive_enum}g;

    #tlm type changes
    $cnt += $line =~ s{(\btlm\S+)_export(_decl)?([^\s]*)\b}{$1_imp$2$3}g;
    $cnt += $line =~ s{\btlm_(put|get|peek|get_peek|poke|slave|master|transport)_(port|export|imp|imp_decl|export_node)([^\s]*)\b}{ovm_$1_$2$3}g;
    $cnt += $line =~ s{(\b)tlm_b_}{$1ovm_blocking_}g;
    $cnt += $line =~ s{(\b)tlm_nb_}{$1ovm_nonblocking_}g;
    $cnt += $line =~ s{export_node(\b)}{export$1}g;
    if($line =~ /(w+)\s*\.\s*(get|put)_in\b/ && $type_map{$1} =~ /^tlm_fifo/)
    {
      $cnt += $line =~ s{\.\s*(get|put)_in\b}{\.blocking_$1_export}g;
    }
    $cnt += $line =~ s{\bURM_ZERO_OR_MORE_BOUND\b}{0,'hffff}g;
    $cnt += $line =~ s{\bURM_ONE_OR_MORE_BOUND\b}{1,'hffff}g;
    $cnt += $line =~ s{\burm_fifo\b}{tlm_fifo}g;

    #work around bug in tlm nb put ports
    if($line =~ /\b(\w+)\.\s*try_put|can_put|try_get|can_get\s*\(/)
    {
      if($type_map{$1} =~ /^(tlm_|ovm_)/) 
      {
         $cnt += $line =~ s{^(\s*)(.*)(\b\w+)(\s*\.\s*(try_put|can_put|try_get|can_get)\s*\(\s*\w+\s*\).*)}{$1if($3.size())\n$1  $2$3$4\n};
      }
    }

    #Method changes
    $cnt += $line =~ s{(\b)create_unit(\b)}{$1create_component$2}s;
    #In urm there is a global and local version of get_unit static method.
    $cnt += $line =~ s{([\s=])get_unit([(\s])}{$1ovm_component::find_component$2}s;
    $cnt += $line =~ s{(\b)get_unit((s?)\b)}{$1find_component$2}s;

    #Removed/changed prototypes
    if($curr = ($line =~ s{(\b),\s*urm_copier\s*opt(\b)}{$1$2})) {
      $opt = "copier";
      $cnt += $curr;
    }
    if($curr = ($line =~ s{\(\s*urm_copier\s*opt\b=\bnull\s*\)}{()})) {
      $opt = "";
      $cnt += $curr;
    }
    if($curr = ($line =~ s{(\b)urm_comparer opt(\b)}{$1ovm_comparer comparer$2})) {
      $opt = "comparer";
      $cnt += $curr;
    }
    if($curr = ($line =~ s{(\b)urm_recorder opt(\b)}{$1ovm_recorder recorder$2})) {
      $opt = "recorder";
      $cnt += $curr;
    }
    if($line =~ /(\b)endfunction(\b)/) {
      $opt = "opt";
    }
   if($line =~ m{^[^/].*(,?)\s*opt\b}) {
      if($1 eq ",") {
        $cnt += $line =~ s{^(.*)(,?\s*opt\b)}{$1}g ;
      }
      elsif($opt eq "copier") {
        if($line =~ /\(\s*opt\s*\)/) {
          $cnt += $line =~ s{\(\s*opt\s*\)}{()}g;
        } 
        else {
          print_to_log "$toolname_G: *E,NOEQIV: OVM does not implement a policy class " .
               "for ovm_copier. This line will be commented out: $file ($.)\n\n";
          $cnt += $line =~ s{^}{//};
        }
      }
      else {
        $cnt += $line =~ s{(((,\s)|\b)opt\b)|(\bopt\b,?)}{$3$opt}g;
      }
    }
    if($line =~ /(\b[\w\d_]+)\.severity\b/)
    {
      if($type_map{$1} eq "urm_comparer")
      {
        $cnt += $line =~ s{(\b[\w\d_]+)\.severity\b}{$1.sev};
      }
    }
    $cnt += $line =~ s{\.print_object\s*\((\s*[\w\d]+\s*)\)}{.print_object("$1",$1)}g;
    $cnt += $line =~ s{\.print_object\s*\((\s*[\w\d]+\s*),(\s*\"[\w\d]+\s*\")\)}{.print_object($2,$1)}g;
    $cnt += $line =~ s{\.(bindp|binde|bindi)([(\s])}{.connect$2}g;
    $cnt += $line =~ s{(\b)(\S+::run_test)(\b)}{ovm_env::run_test}g;
    if($line =~ /[.]wait_for\(\s*\d+\s*\)/)
    {
      print_to_log "$toolname_G: *W,PRTIMP: OVM does not support a timeout for a barrier wait".
        ": $file ($.)\n\n";
      $cnt += $line =~ s{[.]wait_for\(\s*\d+\s*\)}{.wait_for()};
    }
    $cnt += $line =~ s{(\b)(urm_message_handler::set_global_verbosity)(\b)}{ovm_urm_report_server::set_global_verbosity}g;
    $cnt += $line =~ s{\b(set_sub_sequencers\s*\(\s*\)\s*;)}{//$1};

    #Macro changes
    $cnt += $line =~ s{(\)burm_data)}{$1ovm_object};
    $cnt += $line =~ s{`urm_sequencer_set_sequences_and_item}{`ovm_update_sequence_lib_and_item};
    $cnt += $line =~ s{`urm_sequencer_set_sequences}{`ovm_update_sequence_lib};
    $cnt += $line =~ s{(`urm_do_seq(_with)?\s*\(\s*\w+\s*,\s*)p_sequencer\s*\.\s*([\w\.]+)\s*\)}{$1p_sequencer.seq_cons_if["$3"])};

    #Add ovm_ to globals
    $cnt += $line =~ s{\b($urm_global_lc_G)\b}{ovm_$1}g;
    $cnt += $line =~ s{\b($urm_global_uc_G)\b}{OVM_$1}g;

    $cnt += $line =~ s{\bfinish_on_completion\b}{ovm_env::finish_on_completion}g;

    #Sequencer to driver interaction
    if($line =~ /(?<!seq_item_prod_if)\s*[.]\s*(try_next_item|get_next_item|item_done_trigger)\b/)
    {
      print_to_log "$toolname_G: *W,PRTIMP: direct usage of urm_bfm::$1 has been replaced ".
        "with a call to ovm_driver::seq_item_prod_if.$1. Make sure that the sequencer and ".
        "driver are correctly connected together" .
        ": $outfile ($.)\n\n";
      $cnt += $line =~ s{\S+\s*[.]\s*get_next_item\((\s*\S+\s*)\)}{seq_item_prod_if.get_next_item($1)};
      $cnt += $line =~ s{\S+\s*[.]\s*try_next_item\((\s*\S+\s*)\)}{seq_item_prod_if.try_next_item($1)};
      $cnt += $line =~ s{\S+\s*[.]\s*item_done_trigger\((\s*)\)}{seq_item_prod_if.item_done()};
    }
    if($line =~ /(.*\s+)driver\.sequencer\s*=\s*(this\.)?sequencer\s*;/)
    {
      print_to_log "$toolname_G: *W,DRVSEQ: found connection of URM bfm to driver, attempting ".
        "to change to a driver to sequencer connection. Verify that this is correct".
        ": $outfile ($.)\n\n";
      $line = "$1driver.seq_item_prod_if.connect_if(sequencer.seq_item_cons_if);\n";
    }
    $cnt += $line =~ s{\bp_driver\.}{p_sequencer.};

    #Catch deprecated types
    if ($line =~ /\burm_gui_printer\s*(\w+)/)
    {
      $gui = $1;
      print_to_log "$toolname_G: *W,DEPFET: urm_gui_printer is unsupported. This will be replaced by the table printer".
           ": $file ($.)\n\n";
      $cnt += $line =~ s{\burm_gui_printer\b}{urm_table_printer}g;
    }
    else 
    {
      if($gui ne "") { $cnt += $line =~ s{(\s*$gui\s*\.\s*knobs\s*\.\s*fname)}{//$1}; }
    }

    #Catch all to catch simple urm to ovm chagnes
    $cnt += $line =~ s{(\b)urm_}{$1ovm_}g;
    $cnt += $line =~ s{(\b)URM_}{$1OVM_}g;

    #Convert messaging macros back
    $cnt -= $line =~ s{$urm_message_macros}{`urm_$1};

    if(($VERBOSE_ARG != 0) && ($pcnt != $cnt)) {
      print_to_log "... $file: $.\n" .
            "<<< $lineorig" .
            ">>> $line";
    }

    $pcnt = $cnt;

    if($in_build == 0 || $is_virt_seq == 0)
    {
      print OUTFILE $line;
    }
    else
    {
      $build_imp .= $line;
    }
  } ### End of if multiline
  } ### End of while <INFILE>

  if($ifile eq $ofile)
  {
    if($cnt != 0)
    {
      if(-w $ifile)
      {
        $outfile =~ s/\.ovm$//;
        system ("cp $ifile $ifile.urm");
        system ("mv $ifile.ovm $ifile");
      }
      else
      {
        print_to_log "$toolname_G: *W,NOWRT: Unable to write to $ifile, output is in $ifile.ovm\n\n";
      }
    }
    else { system("rm -f $ifile.ovm"); }
  }
 
  print_to_log "  $cnt modifications made to $file, stored in $outfile\n" if ($VERBOSE_ARG != 0 && $cnt != 0);
  print_to_log "  0 modifications made to $file\n" if ($VERBOSE_ARG != 0 && $cnt == 0);

  if($cnt != 0)
  {
    ++$file_mod_G;
  }
  $mod_G += $cnt;
}

#-------------------------------------------------------------------------------
#
# dump_synopsis
#
#-------------------------------------------------------------------------------
# Descript : Dump argument list and exit(1);
#
# Args     : 1 FILEHANDLE to write to; must be opened for write
#            2 banner string
#
# Globals  : none
# Return   : none
# SideEfft : exits simulation after dumping
#-------------------------------------------------------------------------------

sub dump_synopsis
{
  my ($FILEH, $banner) = @_;

  print $FILEH <<USAGE;
$banner
Usage:

  $toolname_G [options] directory(s) and/or source_file(s)

Description:

  Convert source files from URM to OVM. If a directory is provided, all
  applicable files (files with a .sv or .svh extension) in the directory
  hierarchy are converted. The output is placed in a new directory in the
  parent directory of the input directory, with a name ovm_<directory> (or a
  separate output directory may be specified with the -outdir option). If a
  source file is provided directly, then that file is modified and the original
  is placed into the file named <file>.urm.

Notes:

  1. Sequencer to driver connections are not created by this script in the
     general case. In URM, driver (OVM sequencer) to bfm (OVM driver)
     connections are done with explicit reference assignments. In OVM, the
     connections is done by calling ovm_driver::seq_item_prod_if.connect_if
     (ovm_sequencer::seq_item_cons_if). Since this connection requires explicit
     knowledge of how drivers and sequencers are to be connected, it cannot be
     done automatically without creating a full parse tree, which this utility
     does not do.

     This utility will attempt to make the connection in the special case that
     the naming convention for the bfm inside of the agent is "bfm", driver
     inside the bfm is "driver", and the connection is done using the form
     "bfm.driver=driver".

  2. URM does not contain TLM analysis ports, so it is common to use TLM put
     ports as an alternative. While this works in many cases, it is good
     practice to replace these usages of put ports with analysis ports.

  3. All occurrences of driver are changed to sequencer and all occurrences of
     bfm are changed to driver to follow the OVM naming convention. By default,
     file names are not changed; use the -modname argument to have file names
     (and `include directives) changed as well.

Options:

  The following options are available (all are case-insensitive).

  -EXT <list>          Specify extensions to search for files in directories.
                       By default, the extensions .sv and .svh are used. <list>
                       is a colon separated list.
  -HELP                Display this help
  -LOG <file>          Name of the output log. The default name is urm2ovm.log.
  -MODNAME             Modify file names that contain driver and bfm to use the
                       OVM terminology, sequencer and driver.
  -NOMODNAME           Do not modify file names that contain driver and bfm to
                       use the OVM terminology, sequencer and driver. This is the
                       default.
  -NORECURSE           Do not recursively descend directories.
  -OUTDIR <dir>        Use <dir> as the output directory when directories are
                       processed.
  -RECURSE             When a directory is used, specifies to recursively
                       descend (the default)
  -VERBOSE             Indicate each line that is being changed
  -VERSION             Prints the version number

USAGE

  exit (1);
}

