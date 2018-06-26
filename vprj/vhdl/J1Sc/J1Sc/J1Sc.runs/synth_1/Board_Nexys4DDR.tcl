# 
# Synthesis run script generated by Vivado
# 

proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
create_project -in_memory -part xc7a100tcsg324-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.cache/wt [current_project]
set_property parent.project_path /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.xpr [current_project]
set_property default_lib work [current_project]
set_property target_language VHDL [current_project]
set_property ip_output_repo /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
read_vhdl -library work {
  /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.srcs/sources_1/imports/J1Sc/src/main/vhdl/arch/Nexys4DDR/PLL.vhd
  /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.srcs/sources_1/imports/J1Sc/gen/src/vhdl/J1Nexys4X.vhd
  /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.srcs/sources_1/imports/J1Sc/src/main/vhdl/arch/Nexys4DDR/Board_Nexys4DDR.vhd
}
# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.srcs/constrs_1/imports/nexys4ddr/Clocks.xdc
set_property used_in_implementation false [get_files /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.srcs/constrs_1/imports/nexys4ddr/Clocks.xdc]

read_xdc /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.srcs/constrs_1/imports/nexys4ddr/Debug.xdc
set_property used_in_implementation false [get_files /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.srcs/constrs_1/imports/nexys4ddr/Debug.xdc]

read_xdc /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.srcs/constrs_1/imports/nexys4ddr/Pins.xdc
set_property used_in_implementation false [get_files /home/streit/src/scala/J1Sc/vprj/vhdl/J1Sc/J1Sc/J1Sc.srcs/constrs_1/imports/nexys4ddr/Pins.xdc]

set_param ips.enableIPCacheLiteLoad 0
close [open __synthesis_is_running__ w]

synth_design -top Board_Nexys4DDR -part xc7a100tcsg324-1


# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef Board_Nexys4DDR.dcp
create_report "synth_1_synth_report_utilization_0" "report_utilization -file Board_Nexys4DDR_utilization_synth.rpt -pb Board_Nexys4DDR_utilization_synth.pb"
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]