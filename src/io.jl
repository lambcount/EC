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

        dirs_files = readdir(dir,join=true)
        files = [dirs_files[i] for i in 1:length(dirs_files) if isdir(dirs_files[i]) == false]
<<<<<<< Updated upstream
        filenames = first.(splitext.(last.(split.(files,"\\"))))
        fileext = last.(splitext.(last.(split.(files,"\\"))))
=======
        if Sys.isapple() == true
            filenames = first.(splitext.(last.(split.(files,'/'))))
            fileext = last.(splitext.(last.(split.(files,'/'))))
        elseif Sys.iswindows() == true
            filenames = first.(splitext.(last.(split.(files,"\\"))))
            fileext = last.(splitext.(last.(split.(files,"\\"))))
        end
>>>>>>> Stashed changes

        idxs = findall(x-> x==(_measurement),filenames)

        if isempty(idxs) == true
            error("There is no Measurement named $(_measurement) in $(dir).")
        else
            idx_file = idxs[1]

            if fileext[idx_file] == ".csv"
                data = readdlm(files[idx_file])
                _volt = data[:,1]
                _curr = data[:,2]
                    return _volt,_curr

            elseif fileext[idx_file] == ".txt"
                data = readdlm(files[idx_file])
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

function ec_list(; dir::AbstractString = "./Data/EC")
    dirs_files = readdir(dir,join=true)
    files = [dirs_files[i] for i in 1:length(dirs_files) if isdir(dirs_files[i]) == false]
<<<<<<< Updated upstream
    filenames = first.(splitext.(last.(split.(files,"\\"))))
=======
    if Sys.isapple() == true
        filenames = first.(splitext.(last.(split.(files,'/'))))
    elseif Sys.iswindows() == true
        filenames = first.(splitext.(last.(split.(files,"\\"))))
    end
>>>>>>> Stashed changes
    
    return DataFrame(Measurement = filenames)
end
