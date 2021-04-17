using HDF5
import Base: findall
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
        filenames = first.(splitext.(last.(split.(files,'/'))))
        fileext = last.(splitext.(last.(split.(files,'/'))))

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
    function ec_list(;   dir::AbstractString = "./test/Data/EC",
        inexact::AbstractString  = "",
        measurement::AbstractString = "",
        scan_rate = "",
   )

e.g.
    julia> ec_list()
    4×3 DataFrame
     Row │ Filename     Measurment  ScanRate 
         │ String       String      Any      
    ─────┼───────────────────────────────────
       1 │ EC-001-001   n/A         n/A
       2 │ EC-XXX-XXX   n/A         n/A
       3 │ EC-test_CV   CV          50.0
       4 │ EC-test_OCP  OCP         n/A
    
    >julia ec_list(inexact="001-001)
"""
function ec_list(;   dir::AbstractString = "./test/Data/EC",
                     inexact::AbstractString  = "",
                     measurement::AbstractString = "",
                     scan_rate = missing ,
                     #pump::AbstractString = "",
                     ex_na = false
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
    df = DataFrame(Filename = filenames, Measurement = measurements, ScanRate= scan_rates)

   #if ex_na == false
   #   return  df[((df.Measurement .== measurement) .| (df.Measurement .== "n/A")),:]
   #elseif ex_na == true
   #    return  df[(df.Measurement .== measurement),:]

    #end


end

    
