__precompile__()
module EC

using DelimitedFiles,DataFrames

include("./data.jl")
include("./io.jl")
include("./scinote.jl")

export
    ec_grab,
    ec_list,
    cycle,
    total_cycles,
    get_params,
    idx_cycle,
    post_plot
end
