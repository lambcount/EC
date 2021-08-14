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
    post_plot
end
