using HDF5
import Base: findall

function get_fnames_and_types(filepath)
    filenames = first.(splitext.(last.(split.(filepath,'/'))))
    fileext = last.(splitext.(last.(split.(filepath,'/'))))

    return filenames,fileext
end
"""
    ec_grab(measurement::AbstractString; dir::AbstractString = "./Data/EC")

Fetch the CV and OCP Measurements from your dir. 

eg. 
    julia> v,c = ec_grab("001-001",dir = "..")\n\t


You can also grab the DataFrame from ec_list(). Be sure that the experiments in ec_list() all are either CV or OCP or another experiment. Otherwise this will result in an error.
    julia>v=ec_grab(ec_list(measurement="OCP"))
    
    julia>v=ec_grab(ec_list(measurement="CV"))
"""
function ec_grab(measurement::AbstractString; dir::AbstractString = "./Data/Electrochemistry_Data/")
    if occursin("EC-",measurement) == false
        _measurement = "EC-"*measurement
    else
        _measurement = measurement
    end

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

                elseif _measurement == "CV"
                    data = h5open(files[idx_file]) do fid
                        read(fid["CV"]["Data"])
                        end
                    _volt = data[:,1]
                    _curr = data[:,2]

                    return _volt,_curr
                    end                       
                
            elseif fileext[idx_file] == ".csv"
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
            @show data[1]
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
Check the current range of  CV or Charge measurement(.h5 file).
    get_curr_range(file::AbstractString)

e.g.
    julia> get_measurement("./EC-CV.h5")
    "CV"
"""
function get_curr_range(file::AbstractString)
    _measurement = get_measurement(file)

    _curr_range =  h5open(file) do fid
        read(HDF5.attributes(fid[_measurement]["Data"])["Current Range [A]"])   
    end
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
    if _measurement == "CV"

        attributes = [
            "Sample Rate [Hz]",
            "Scan Rate [mV/s]",
            "Current Range [A]",
            "Current Filter [Hz]",
            "Bandwidth Filter [Hz]"
        ]

        values = [HDF5.attributes(h5open(file)["CV"]["Data"])[attributes[i]] |> read for i in 1:length(attributes)]
        close(h5open(file))
        return [attributes values]
        

    elseif _measurement == "OCP"

        attribute = "Sample Rate [Hz]"

        value = HDF5.attributes(h5open(file)["OCP"]["Data"])[attribute] |> read
        close(h5open(file))

        return [attribute value]

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
function ec_list(;   dir::AbstractString = "./Data/Electrochemistry_Data/ ",
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

    measurements = [filetype[i] == ".h5" ? get_measurement(files[i]) : "n/A" for i in 1:length(files)]
    scan_rates = [(filetype[i] == ".h5" && get_measurement(files[i]) == "CV") ? get_params(files[i])[2,2] : "n/A" for i in 1:length(files)]
    _df = DataFrame(Filename = filenames, Measurement = measurements, ScanRate= scan_rates, Path=files)

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

    
