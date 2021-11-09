__precompile__()
module EC

using DelimitedFiles,DataFrames

include("./data.jl")
include("./io.jl")
include("./scinote.jl")
include("./elements.jl")
include("./struct.jl")
include("./build_circuits.jl")
include("./savitzkyGolay.jl")

export
    ec_grab,
    ec_list,
    cycle,
    total_cycles,
    get_params,
    idx_cycle,
    post_plot,
    savitzky_golay_filter,
    build_circuit,
    get_circuit,
    freq,
    conv_circuit
end
