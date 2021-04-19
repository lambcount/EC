__precompile__()
module EC

using DelimitedFiles,DataFrames

include("./data.jl")
include("./io.jl")
#include("./struct.jl")

export
    Measurement,
    ec_grab,
    ec_list,
    cycle,
    total_cycles,
    get_measurement,
    get_params,
    #get_curr_range,

end
