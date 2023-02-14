# Create project, specify part, and update project settings
create_project -force multicycle_io ./proj
set_property "part" "xc7a35tcpg236-1" [get_projects [current_project]]
source ../resources/new_project_settings.tcl
# Add the top-level I/O system and constraints file (provided in the lab)
add_files multicycle_iosystem.sv
add_files -fileset constrs_1 ../resources/iosystem/iosystem.xdc
# Add files from your previous labs and set the include directories
add_files ../lab06/riscv_multicycle.sv
add_files ../lab05/riscv_simple_datapath.sv ../include/riscv_datapath_constants.sv
add_files ../lab03/regfile.sv ../lab02/alu.sv ../include/riscv_alu_constants.sv
set_property include_dirs {../include} [current_fileset]
# Add the files associated with the top-level I/O system
add_files ../resources/iosystem/iosystem.sv
add_files ../resources/iosystem/io_clocks.sv
add_files ../resources/iosystem/riscv_mem.sv
add_files ../resources/iosystem/cores/SevenSegmentControl4.sv
add_files ../resources/iosystem/cores/debounce.sv
add_files ../resources/iosystem/cores/rx.sv
add_files ../resources/iosystem/cores/tx.sv
add_files ../resources/iosystem/cores/vga/vga_ctl3.vhd
add_files ../resources/iosystem/cores/vga/charGen3.vhd
add_files ../resources/iosystem/cores/vga/vga_timing.vhd
add_files ../resources/iosystem/cores/vga/list_ch13_01_font_rom.vhd
add_files ../resources/iosystem/cores/vga/charColorMem3BRAM.vhd
add_files ../resources/iosystem/cores/vga/bramMacro.v
# Add testbench simulation set
#create_fileset -simset sim_2
#add_files -fileset sim_2 -norecurse tb_multicycle_io.sv