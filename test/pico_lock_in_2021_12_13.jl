using Statistics,DelimitedFiles

path = "/Users/lammerzahl/Git/Share_Library/FcC11/data/exp_raw/EC/bulk/2021_12_13/"
dir = readdir(path) 
m_pathes = [joinpath(path,dir[i]) for i in 1:length(dir) if occursin(".csv", dir[i])]


function correct_data(data,column,RV)
    
    # The first column is the time, so no RV correction needed
    if column !== 1

       data[3:end,column] = data[3:end,column] / RV
    else
        # correct strange pico log artifact where the first value is not utf-8 format, but '\x00012'
        r = r"(\d+)"
        first = match(r,data[3,column]).captures[1]
        _first = parse(Float64,first)
        data[3,column]  = _first
    end        
    # Make a Float64 array
    ch = Array{Float64,1}(undef,(size(data,1)-2)) 

    for i in 1:size(data,1)-2
        ch[i] = data[i+2,column]
    end
    # Check if the channel range is in V otherwise correct values
    if data[2,column] == "( mV )"
        ch  = ch ./ 1e3
    end

    return ch    
end

function import_pico_logger(path;RV=10)
    data = readdlm(path,',')
 

    ch_1 = correct_data(data,1,RV)
    ch_2 = correct_data(data,2,RV)
    ch_3 = correct_data(data,3,RV)
    ch_4 = correct_data(data,4,RV)
    ch_5 = correct_data(data,5,RV)

    return [ch_1 ch_2 ch_3 ch_4 ch_5]

end

potential_amplitude = 5e-3

f = [
    1e4,
    2.83e3,
    2.38e3,
    1.63e3,
    1.03e3,
    7.67e2,
    5.12e2,
    3.06e2,
    2.03e2,
    1.01e2,
    7e1,
    5.3e1,
    3e1,
    2e1,
    1e1,
    7,
    5,
    3
]

sens = [
    0.1,
    0.1,
    0.1,
    0.1,
    0.1,
    0.1,
    0.1,
    0.1,
    0.1,
    0.01,
    0.01,
    0.01,
    0.01,
    0.001,
    0.001,
    0.001,
    0.003,
    0.003,
    0.001
]

if length(m_pathes) == length(f)
    println("Up you go.")

end

all_data = import_pico_logger.(m_pathes)

imp = [potential_amplitude/(mean(all_data[i][:,4]/1000)) for i in 1:size(all_data,1)]
phase = [mean(all_data[i][:,5]) *1000 for i in 1:size(all_data,1)]
