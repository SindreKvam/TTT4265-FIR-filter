from vunit import VUnit
import os

vu = VUnit.from_argv()

vu.add_com()

smk_lib = vu.add_library("smk_lib")
smk_lib.add_source_files("*/*.vhd")

ieee_proposed_lib = vu.add_library("ieee_proposed")
# ieee_proposed_lib.add_source_files("quartus/lib/vhdl/ieee_proposed/*.vhdl", vhdl_standard="1993")
ieee_proposed_lib.add_source_file("quartus/lib/vhdl/ieee_proposed/math_utility_pkg.vhdl", vhdl_standard="2008")
ieee_proposed_lib.add_source_file("quartus/lib/vhdl/ieee_proposed/fixed_float_types_c.vhdl", vhdl_standard="2008")
ieee_proposed_lib.add_source_file("quartus/lib/vhdl/ieee_proposed/fixed_pkg_c.vhdl", vhdl_standard="1993")

for tb in smk_lib.get_test_benches():

    # Load any wave.do files found in the testbench folders when running in GUI mode
    tb_folder = os.path.dirname(tb._test_bench.design_unit.file_name)
    wave_file = os.path.join(tb_folder, 'wave.do')
    if os.path.isfile(wave_file):
        tb.set_sim_option("modelsim.init_file.gui", wave_file)

    tb.set_sim_option("modelsim.vsim_flags.gui", ["-voptargs=+acc"])


vu.main()