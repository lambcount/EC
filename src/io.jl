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

function ec_list(;   dir::AbstractString = "./Data/EC",
                     scinote::Bool = true,
                     inexact::AbstractString  = "",
                     measurement::AbstractString = "",
                     scan_rate = "",
                     pump::AbstractString = ""
                    )
                    
    dirs_files = readdir(dir,join=true)
    files = [dirs_files[i] for i in 1:length(dirs_files) if isdir(dirs_files[i]) == false]
    filenames = first.(splitext.(last.(split.(files,"\\"))))
    
    return DataFrame(Measurement = filenames)
end


"""
    html2string(html)

Convert a html to a normal String.
"""
function html2string(html)
    div_start = "<div>"
    div_end = "</div>"
    space = "&nbsp;"
    
    _str = replace(html,div_start=>"") 
    _str = replace(_str,div_end=>"") 
    _str = replace(_str,space=>"") 
            
    return _str
    
end

"""
comment2measurement(str)
Extract Measurment and other comments from string.
"""
function comment2measurement(str)

    _idx = findall(x-> isspace(x)==true,str)

    if isempty(_idx)==true
        measurement = str
        pump = ""
        rest = ""
        return measurement,pump,rest
    else
        idx_start=[1;[i for i in 2:length(str) if (isprint(str[i]) == true) && (isspace(str[i-1])==true)]]
        idx_end=[[i for i in 1:length(str)-1 if (isprint(str[i]) == true) && (isspace(str[i+1])==true)];length(str)]

        if length(idx_start) == 1

            measurement = str[idx_start[1]:idx_end[1]]
            pump = ""
            rest= ""

            return measurement,pump,rest

        elseif length(idx_divs) == 2

            measurement = str[idx_start[1]:idx_end[1]]
            pump = str[idx_start[2]:idx_end[2]]
            rest = ""

            return measurement,pump,rest

        elseif length(idx_divs) > 2

            measurement = str[idx_start[1]:idx_end[1]]
            pump = str[idx_start[2]:idx_end[2]]
            rest = str[idx_start[3]:end]

            return measurement,pump,rest
        end

    end

end
