using HDF5
import Base: findall

function get_fnames_and_types(filepath)

    if Sys.isapple() == true
        filenames = first.(splitext.(last.(split.(filepath,'/'))))
        fileext = last.(splitext.(last.(split.(filepath,'/'))))
    elseif Sys.iswindows() == true
        filenames = first.(splitext.(last.(split.(filepath,"\\"))))
        fileext = last.(splitext.(last.(split.(filepath,"\\"))))
    end

    return filenames,fileext
end
"""
    ec_grab(measurement::AbstractString; dir::AbstractString = "./Data/EC")

Fetch the CV and OCP Measurements from your dir. 

eg. 
    julia> v,c = ec_grab("EC-001-001",dir = "..")\n\t


You can also grab the DataFrame from ec_list(). Be sure that the experiments in ec_list() all are either CV or OCP or another experiment. Otherwise this will result in an error.
    julia>v=ec_grab(ec_list(measurement="OCP"))
    
    julia>v=ec_grab(ec_list(measurement="CV"))
"""
function ec_grab(_measurement::AbstractString; dir::AbstractString = "./test/Data/EC")


        dirs_files = readdir(dir,join=true)
        files = [dirs_files[i] for i in 1:length(dirs_files) if isdir(dirs_files[i]) == false]
        filenames,fileext =get_fnames_and_types(files)

        idxs = findall(x-> x==(_measurement),filenames)

        if isempty(idxs) == true
            error("There is no Measurement named $(_measurement) in $(dir).")
        else
            idx_file = idxs[1]
        
            if fileext[idx_file] == ".h5"
                _measurement =  get_measurement(files[idx_file])

                if _measurement == "OCP"
                    _volt = h5open(files[idx_file]) do fid
                                read(fid["OCP"]["Data"])
                            end

                    return _volt

                elseif match(r"\D+",_measurement).match == "CV"
                    if _measurement == "CV"

                    data = h5open(files[idx_file]) do fid
                        read(fid["CV"]["Data"])
                        end
                    _volt = data[:,1]
                    _curr = data[:,2]

                    return _volt,_curr

                    else

                        measurments = h5open(files[idx_file]) do fid
                            keys(fid)
                        end

                        data = [h5open.(files[idx_file])[measurments[i]]["Data"] |> read for i in 1:length(measurments) ]

                        close(h5open(files[idx_file]))
                        
                        if length(data) > 1
                        
                            _volt = [data[i][:,1] for i in 1:length(data)]
                            _curr = [data[i][:,2] for i in 1:length(data)]
                        else
                                                    
                            _volt = data[1][:,1]
                            _curr = data[1][:,2]

                        end

                        return _volt,_curr
                    end
                elseif _measurement == "OCP Pump-Probe"

                    _volt = h5open(files[idx_file]) do fid
                        read(fid[_measurement]["Voltage"])
                    end
                    _positions = h5open(files[idx_file]) do fid
                        read(fid[_measurement]["SHBC Positions"])
                    end

                    if haskey(h5open(files[idx_file])[_measurement],"IR Power") == true
                        _power = h5open(files[idx_file]) do fid
                            read(fid[_measurement]["IR Power"])
                        end
                        return _volt,_positions,_power
                    else 
                        return _volt,_positions


                    end
                end                       
                
            elseif fileext[idx_file] == ".csv"
                data = readdlm(files[idx_file])
                if last(size(data)) > 1
                _volt = data[:,1]
                _curr = data[:,2]
                    return _volt,_curr
                else
                    _volt = data[:,1]
                    return _volt
                end

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

function ec_grab(df::DataFrame)

    path = df[:,end]
    fileext= get_fnames_and_types(path)[2]

    data=[]
    for i in 1:first(size(df))
        if fileext[i] == ".h5"
            _measurement = get_measurement(path[i])
            _data = h5open(path[i]) do fid
                read(fid[_measurement]["Data"])
            end
            push!(data,_data)
        elseif fileext[i] == ".csv"
            _data = readdlm(path[i])
            push!(data,_data)
        elseif fileext[i] == ".txt"
            _data = readdlm(path[i])[:,1:2]
            push!(data,_data)
        end
    end

    if all(last.(size.(data)).== last(size(data[1])))
        if (last(size(data[1])) == 1) || (try size(data[1])[2] catch end === nothing)
            _dim1 = [data[i][:,1] for i in 1:length(data)]
            return _dim1
        elseif last(size(data[1])) == 2
            _dim1 = [data[i][:,1] for i in 1:length(data)]
            _dim2 = [data[i][:,2] for i in 1:length(data)]
            return _dim1,_dim2
        end
    else
        error("The Files you selected in ec_list() are not compatible.")
    end
    

    

    
end



"""
Check if measurement(.h5 file) is a CV or OCP or else.
    get_measurement(file::AbstractString)

e.g.
    julia> get_measurement("./EC-CV.h5")
    "CV"
"""
function get_measurement(file::AbstractString)

    _measurement =  h5open(file) do fid
        keys(fid)[1]
    end
end

"""
Check if current range from CV or CM measurment(.h5 file).
    get_curr_range(file::AbstractString)

e.g.
    julia> get_curr_range("./EC-CV.h5")
    1e-6
"""
function get_curr_range(file::AbstractString)
    _measurement = get_measurement(file)

    if _measurement == "OCP"
        error("This is an Open Circuit Potential Measurement.")

    elseif _measurement == "CV"
        _curr_range =  h5open(file) do fid
            HDF5.attributes(fid[_measurement]["Data"])["Current Range [A]"] |> read
        end
    else
        _curr_range =  h5open(file) do fid
            HDF5.attributes(fid)["Current Range [A]"] |> read
        end
    

    end

    return _curr_range

end


"""
Get Parameters from h5.file
    get_params(file::AbstractString)

e.g. 
    julia> get_params("./EC-CV.h5")
    5×2 Matrix{Any}:
     "Sample Rate [Hz]"        10.0
     "Scan Rate [mV/s]"        50.0
     "Current Range [A]"        1.0e-6
     "Current Filter [Hz]"     10.0
     "Bandwidth Filter [Hz]"  100.0    
"""
function get_params(file::AbstractString)
    _measurement =get_measurement(file)

    
    if match(r"\D+",_measurement).match == "CV"

        attributes = [
            "Sample Rate [Hz]",
            "Scan Rate [mV/s]",
            "Current Range [A]",
            "Current Filter [Hz]",
            "Bandwidth Filter [Hz]"
        ]

        values = try [HDF5.attributes(h5open(file)["CV"]["Data"])[attributes[i]] |> read for i in 1:length(attributes)] catch end

        if isnothing(values) == true
            _add_attributes = [
                "A Potential [mV]",
                "B Potential [mV]"
            ]
            append!(attributes,_add_attributes)
            values = [HDF5.attributes(h5open(file))[attributes[i]] |> read for i in 1:length(attributes)]
        end

        close(h5open(file))
        return Dict(attributes[i] => values[i] for i in 1:length(values))
        

    elseif _measurement == "OCP"

        attribute = "Sample Rate [Hz]"

        value = HDF5.attributes(h5open(file)["OCP"]["Data"])[attribute] |> read
        close(h5open(file))

        return Dict(attribute[i] => value[i] for i in 1:length(value))

    elseif _measurement == "OCP Pump-Probe"

        attributes = [
            "Sample Rate [Hz]",
            "Time [s]",
            "Reference Position",
            "Comment",
        ]



        values = try [HDF5.attributes(h5open(file)[_measurement]["Voltage"])[attributes[i]] |> read for i in 1:length(attributes)] catch end
        close(h5open(file))
        return Dict(attributes[i] => values[i] for i in 1:length(values))

    end

end


"""
Returns the List of all Measurements in dir. Use kwargs to filter the df. 
Use show_na to show older measurements without parameters.\t

    function ec_list(;   dir::AbstractString = "./test/Data/EC",
        inexact::AbstractString  = "",
        measurement::AbstractString = "",
        scan_rate = "",
        show_na=false
   )

e.g.\t\n
    julia> ec_list()
    2×4 DataFrame
    Row │ Filename     Measurement  ScanRate  Path                          
        │ String       String       Any       String                        
   ─────┼─────────────────────────────────────────────────────────────────── \n
      1 │ EC-test_CV   CV           50.0      ./test/Data/EC/EC-test_CV.h5
      2 │ EC-test_OCP  OCP          n/A       ./test/Data/EC/EC-test_OCP.h5



    julia> ec_list(show_na=true)
    4×4 DataFrame
    Row │ Filename     Measurement  ScanRate  Path                          
        │ String       String       Any       String                        
   ─────┼───────────────────────────────────────────────────────────────────\n
      1 │ EC-001-001   n/A          n/A       ./test/Data/EC/EC-001-001.txt
      2 │ EC-XXX-XXX   n/A          n/A       ./test/Data/EC/EC-XXX-XXX.csv
      3 │ EC-test_CV   CV           50.0      ./test/Data/EC/EC-test_CV.h5
      4 │ EC-test_OCP  OCP          n/A       ./test/Data/EC/EC-test_OCP.h5


       
    julia> ec_list(inexact="001-001",show_na=true)
    1×4 DataFrame
    Row │ Filename    Measurement  ScanRate  Path                          
        │ String      String       Any       String                        
   ─────┼──────────────────────────────────────────────────────────────────\n
      1 │ EC-001-001  n/A          n/A       ./test/Data/EC/EC-001-001.txt




    julia> ec_list(scan_rate=50)
    1×4 DataFrame
    Row │ Filename    Measurement  ScanRate  Path                         
        │ String      String       Any       String                       
   ─────┼─────────────────────────────────────────────────────────────────\n
      1 │ EC-test_CV  CV           50.0      ./test/Data/EC/EC-test_CV.h5
"""
function ec_list(;   dir::AbstractString = "./test/Data/EC",
                     inexact::AbstractString  = "",
                     measurement::AbstractString = "",
                     scan_rate = missing ,
                     #pump::AbstractString = "",
                     show_na = false
                    )
                    
    dirs_files = readdir(dir,join=true)
    files = [dirs_files[i] for i in 1:length(dirs_files) if isdir(dirs_files[i]) == false]
    if Sys.isapple() == true
        filenames = first.(splitext.(last.(split.(files,'/'))))
        filetype = last.(splitext.(last.(split.(files,'/'))))
    elseif Sys.iswindows() == true
        filenames = first.(splitext.(last.(split.(files,"\\"))))
        filetype = last.(splitext.(last.(split.(files,"\\"))))
    end

    measurements = [filetype[i] == ".h5" ? match(r"\D+",get_measurement(files[i])).match : "n/A" for i in 1:length(files)]
    scan_rates = [(filetype[i] == ".h5" && (match(r"\D+",get_measurement(files[i])).match == "CV")) ? get_params(files[i])["Scan Rate [mV/s]"] : "n/A" for i in 1:length(files)]
    start_potential = [(filetype[i] == ".h5" && (try get_params(files[i])["A Potential [mV]"] catch end) !== nothing) ? get_params(files[i])["A Potential [mV]"] : "n/A" for i in 1:length(files)]
    end_potential = [(filetype[i] == ".h5" && (try get_params(files[i])["B Potential [mV]"] catch end) !== nothing) ? get_params(files[i])["B Potential [mV]"] : "n/A" for i in 1:length(files)]
    _df = DataFrame(Filename = filenames, Measurement = measurements, ScanRate= scan_rates, A_Potential = start_potential, B_Potential = end_potential, Path=files)

   if show_na == false
        _df=_df[(_df.Measurement .!== "n/A"),:]
    if inexact !== ""
        _df=_df[(occursin.(inexact,_df.Filename) .== true ),:]
    end
    if measurement !== ""
        _df = _df[(_df.Measurement .== measurement),:]
    end
    if scan_rate !== missing
        _df = _df[(_df.ScanRate .== scan_rate),:]
    end
    return _df

   elseif show_na == true
    if inexact !== ""
        _df=_df[(occursin.(inexact,_df.Filename) .== true ),:]
    end
    if measurement !== ""
        _df = _df[((_df.Measurement .== measurement) .| (_df.Measurement .== "n/A")),:]
    end
    if scan_rate !== missing
        _df = _df[(((_df.ScanRate .== scan_rate) .| (_df.ScanRate .== "n/A")) .& (_df.Measurement .== "CV" )),:]
    end
        return _df  

    end

end



