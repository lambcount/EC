__precompile__()
module EC

using DelimitedFiles,DataFrames,LsqFit

include("./data.jl")
include("./io.jl")
include("./scinote.jl")
include("./elements.jl")
include("./struct.jl")
include("./build_circuits.jl")
include("./savitzkyGolay.jl")
include("./imped_data.jl")

export
    ec_grab,
    ec_list,
    cycle,
    total_cycles,
    get_params,
    idx_cycle,
    post_plot,
    calc_time,
    savitzky_golay_filter,
    build_circuit,
    get_circuit,
    freq,
    conv_circuit,
    import_oszi_imped,
    fit_traces_for_imped,
    f_sin,
    calc_time
end
