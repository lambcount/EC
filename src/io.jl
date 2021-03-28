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
        if Sys.isapple() == true
            filenames = first.(splitext.(last.(split.(files,'/'))))
            fileext = last.(splitext.(last.(split.(files,'/'))))
        elseif Sys.iswindows() == true
            filenames = first.(splitext.(last.(split.(files,"\\"))))
            fileext = last.(splitext.(last.(split.(files,"\\"))))
        end

        idxs = findall(x-> x==(_measurement),filenames)

        if isempty(idxs) == true
            error("There is no Measurement named $(_measurement) in $(dir).")
        else
            idx_file = idxs[1]

            if fileext[idx_file] == ".csv"
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

function ec_list(;   dir::AbstractString = "./Data/EC",
                     scinote::Bool = true,
                     inexact::AbstractString  = "",
                     measurement::AbstractString = "",
                     scan_rate = "",
                     pump::AbstractString = ""
                    )
                    
    dirs_files = readdir(dir,join=true)
    files = [dirs_files[i] for i in 1:length(dirs_files) if isdir(dirs_files[i]) == false]
    if Sys.isapple() == true
        filenames = first.(splitext.(last.(split.(files,'/'))))
    elseif Sys.iswindows() == true
        filenames = first.(splitext.(last.(split.(files,"\\"))))
    end

    if scinote == true
    end



    
    return DataFrame(Measurement = filenames)
end

"""
Findall for finding substrings in strings.
"""
function findall(t::Union{AbstractString,Regex}, s::AbstractString; overlap::Bool=false)
    found = UnitRange{Int}[]
    i, e = firstindex(s), lastindex(s)
    while true
        r = findnext(t, s, i)
        isnothing(r) && return found
        push!(found, r)
        j = overlap || isempty(r) ? first(r) : last(r)
        j > e && return found
        @inbounds i = nextind(s, j)
    end
end

function step_names_params(team::Int64,project::Int64,experiment::Int64,task::Int64,protocol::Int64)
    data = get_steps(team::Int64,project::Int64,experiment::Int64,task::Int64,protocol::Int64)
    step_ids = [parse(Int,data[i]["id"]) for i in 1:length(data)]
    comments = [comment2measurement(html2string(data[i]["attributes"]["description"])) for i in 1:length(data)]
    params = [get_step_table(team,project,experiment,task,protocol,step_ids[i]) for i in 1:length(step_ids)]
    df = DataFrame()
        df.Names  = [data[i]["attributes"]["name"] for i in 1:length(data)]
        df.Scan_Rate = [params[i][2] for i in 1:length(params)]
        df.Pump = [params[i][2] for i in 1:length(params)]
        df.Comment  

    
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
