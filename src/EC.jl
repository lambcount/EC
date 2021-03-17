__precompile__()
module EC

using DelimitedFiles

include("./data.jl")
include("./io.jl")

export
    ec_grab,
    cycle

end