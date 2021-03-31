using Gumbo
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
function html2string(html_raw)
    html_parsed = parsehtml(html_raw)
    s = text(html_parsed.root)

end

"""
comment2measurement(str)
Extract Measurment and other comments from string.
"""
function comment2measurement(str)

    _idx = findall(x-> isspace(x)==true,str)
    _idx_s =[_idx[i] for i in 2:length(_idx) if _idx[i] !== _idx[i-1]+1]

    regex = r"(\w*|$)(?:[ ]{2,})"


    if isempty(_idx)==true
        measurement = str
        pump = "Pump: n/a"
        rest = "comment n/a"
        return measurement,pump,rest
    else
        if length(_idx_s) == 0
            matches = collect(eachmatch(regex,str))
            measurement = first(matches).captures[1]
            second = last(matches)
            if occursin("pump",lowercase(str))== true
                pump = "Pump: "* second.captures[1]
            else            
                pump = second.captures[1]
            end
            rest= "comment n/a"

            return measurement,pump,rest

        elseif length(_idx_s) >= 1
            regex2 = r"(?:[ ]{2,})(.*)"

            matches = collect(eachmatch(regex,str))
            measurement = first(matches).captures[1]
            second = last(matches)
            if occursin("pump",lowercase(str))== true
                pump = "Pump: "* second.captures[1]
            else            
                pump = second.captures[1]
            end
            rest =  match(regex2,str[second.offset+length(second.captures[1]):end]).captures[1]

            return measurement,pump,rest
        end
    end

end
