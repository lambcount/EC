__precompile__()
module EC

using DelimitedFiles,DataFrames

include("./data.jl")
include("./io.jl")

export
    ec_grab,
    ec_list,
    cycle,
    total_cycles,
    get_measurement,
    get_params,
    get_curr_range,
    get_eq_anodickathodiccurrents,
    get_ind_eq_anodickathodicpotentials
end
