"""
    ec_grab(measurement::AbstractString; dir::AbstractString = "./Data/EC")

Fetch the CV and OCP Measurements from your dir. 

eg. v,c = ec_grab("001-001",dir = "..")
"""
function ec_grab(measurement::AbstractString; dir::AbstractString = "./Data/EC")
    if occursin("EC-",measurement) == false
        _measurement = "EC-"*measurement
    else
        _measurement = measurement
    end

        files = readdir(dir)
        filenames = first.(splitext.(files))
        fileext = last.(splitext.(files))

        idxs = findall(x-> x==(_measurement),filenames)

        if isempty(idxs) == true
            error("There is no Measurement named $(_measurement) in $(dir).")
        else
            idx_file = idxs[1]

            if fileext[idx_file] == ".csv"
                data = readdlm(joinpath(dir,files[idx_file]))
                _volt = data[:,1]
                _curr = data[:,2]
                    return _volt,_curr

            elseif fileext[idx_file] == ".txt"
                data = readdlm(joinpath(dir,files[idx_file]))
                if typeof(data[1]) == String
                    _volt = data[:,1]
                    _curr = data[:,2]
                    return _volt,_curr
                else
                    _volt = data[2:end,1]
                    _curr = data[2:end,2]
                    return _volt,_curr
                end
            end
        end


end
