include("./elements.jl")
include("./struct.jl")

"""
Fetches all the circuit components and the total number of components.

Notes
-----
raw_circuit = "R_0-p(R_1,C_1)-p(R_2,C_2)-W_1"

julia> all_comp,n_comp = get_components(raw_circuit)
(["R_0", "R_1", "C_1", "R_2", "C_2", "W_1"], 6)
"""
function get_circuit(raw_circuit::AbstractString)
    r= r"(\w{1,3}_\d)"
    r_components = eachmatch(r,raw_circuit) |> collect
    components = [r_components[i].captures[1] |> String for i in 1:length(r_components)]

    len= length(components)

    return components,len
end



function imp_comp(component,components,p,f)
    idx = iden_comp(component,components)
    comp = split(component,"_") |> first

    if comp == "R"

        return R(p[idx],f)
    elseif comp == "C"

        return C(p[idx],f)
    elseif comp == "CPE"

        return CPE(p[idx:idx+1],f)
    elseif comp == "L"

        return L(p[idx],f)
    elseif comp == "W"

        return W(p[idx],f)
    else

        error("
        $(comp) is not a known as a component. The following components can be used:\n 
        \t R, C, CPE, L, W
        ")
    end

end

function iden_comp(component,components)


   idx = findall(x-> x== component,components)[1]
   return idx

end


function conv_circuit(raw_circuit::AbstractString)

    r_s = r"(\((?:[^()]++|(?1))*\))(*SKIP)(*F)|(?<s>\w+_\d+)"
    r_p = r"(?:\G(?!^),|p\()(\w+(?:-(?!p\()\w+)*(?:-p(\((?:[^()]++|(?2))*\)))?)"

    r2 = r"(?:\G(?!^),|\()(\w+(?:-(?!p\()\w+)*(?:-(\((?:[^()]++|(?2))*\)))?)"

    s_components = eachmatch(r_s,raw_circuit) |> collect 
    p_components = eachmatch(r_p,raw_circuit) |> collect

    all_components, circuit_length = get_circuit(raw_circuit)

    id_list = Dict(all_components[i] => Dict("id" => i) for i in 1:circuit_length)
    
    components = Dict()

    if s_components |> isempty == false
        for s_comp in s_components
            _s = s_comp.captures[2] .|> String 
            push!(components, _s => id_list[_s])
        end

    end

    if p_components |> isempty == false

        n=0
        n_p = 1
        n_p_in_p = 0

        _old_p_captures = nothing
        for p_comp in p_components
            if p_comp.captures[2] === nothing && _old_p_captures === nothing
                _p,_p_len = get_circuit(p_comp.captures[1])
                     #check whether this is the start of a new parallel circuit or an existing one
                    if occursin("p(",p_comp.match) == true
                        n += 1
                        n_p = 1
                        push!(components,"parallel_$(n)" => Dict())
                        for _pn in _p 
                            if haskey(components["parallel_$(n)"],"p_$(n_p)") 
                                push!(components["parallel_$(n)"]["p_$(n_p)"], _pn => id_list[_pn])
                            else
                                push!(components["parallel_$(n)"], "p_$(n_p)" => Dict(_pn => id_list[_pn]))
                            end
                        end
                    else
                        n_p += 1
                        for _pn in _p 
                            if haskey(components["parallel_$(n)"],"p_$(n_p)") 
                                push!(components["parallel_$(n)"]["p_$(n_p)"], _pn => id_list[_pn])
                            else
                                push!(components["parallel_$(n)"], "p_$(n_p)" => Dict(_pn => id_list[_pn]))
                            end
                        end 
                    end
            else
                _s_in_p = eachmatch(r_s,p_comp.captures[1]) |> collect

                if p_comp.match[1] == 'p'
                    n += 1
                    n_p = 1
                elseif p_comp.match[1] == ','
                    n_p += 1
                end  
                p_components_in_p = eachmatch(r2,p_comp.captures[2]) |> collect

                for _p_in_p in p_components_in_p
                    if haskey(components,"parallel_$(n)") == false
                        push!(components,"parallel_$(n)" => Dict("p_$(n_p)" => Dict()))
                    elseif haskey(components["parallel_$(n)"],"p_$(n_p)") == false
                        push!(components["parallel_$(n)"], "p_$(n_p)" => Dict())
                    end                        
                    n_p_in_p += 1
                    _p,_len = get_circuit(_p_in_p.captures[1])
                    if n_p_in_p == 1
                        push!(components["parallel_$(n)"]["p_$(n_p)"],"parallel" => Dict())
                    end
                    push!(components["parallel_$(n)"]["p_$(n_p)"]["parallel"] , "p_$(n_p_in_p)" => Dict())

                    for _ps in _p
                        push!(components["parallel_$(n)"]["p_$(n_p)"]["parallel"]["p_$(n_p_in_p)"], _ps => id_list[_ps])
                    end
                end
                if _s_in_p |> isempty == false
                    for s_comp in _s_in_p
                        _s = s_comp.captures[2] .|> String
                        push!(components["parallel_$(n)"]["p_$(n_p)"], _s => id_list[_s])
                    end
                end                
            end
            n_p_in_p = 0
            _old_p = p_comp.captures[2]
        end       
    end    
    if (p_components |> isempty == true) && (s_components |> isempty == true )
        error!("Cant find any elements in your circuit string. Check it.")
    elseif components |> isempty == true
        error!("There seems to be something wrong in interpreting the components. Check your syntax with ?build_circuit")
    end
    return components
end


"""
Calculate the Impedance of a custom Circuit. The input circuit string should look like circuit="R_i-p(R_j,C_k)". For series circuits use '-' for parallel p(X_1,X_2).\n 
The following circuit components can be used: \n 
\t R \t [Ohm]\t p=1 \n
\t C \t [F]\t p=1 \n
\t CPE \t [F]\t p=2 \n
\t L \t [H]\t p=1 \n
\t W \t [Ohm/√sec] p=1 \n
"""
function build_circuit(raw_circuit,p,f)
   
    components,components_length = get_circuit(raw_circuit)
    circuit = conv_circuit(raw_circuit)

    imp = []

    for key_1 in keys(circuit)
        if occursin("parallel",key_1) == false
            _imp = imp_comp(key_1,components,p,f)
            push!(imp,_imp)
        else
            key_2 = keys(circuit[key_1])
            dicts_p = [circuit[key_1][_k] for _k in key_2]

            p_imp = []   

            for k in dicts_p
                p_k = []              

                key_3   = keys(k)
               
                for key in key_3
                    if occursin("parallel",key) == true
                        key_4 = dicts_p[k][key]
                        dicts_p_2 = [dicts_p[k][key][_k] for _k in key_4]
                        p_imp_2 = []
                            for k_2 in dicts_p_2 
                                s_in_p2 = keys(k_2)
                                s_in_p_imp = []
                                for s in s_in_p2
                                    _imp = imp_comp(s,components,p,f)
                                    push!(s_in_p_imp,_imp)
                                end
                                push!(p_imp_2,series(s_in_p_imp))
                            end
                        push!(p_k,p_imp_2)
                    else
                        
                        _imp = imp_comp(key,components,p,f)
                        push!(p_k,_imp)
                    end    
                end
                push!(p_imp,series(p_k))
            end                
            push!(imp,parallel(p_imp))            
        end
    end
    return Circuit(raw_circuit,circuit,imp)         
end


#test = [
#    "R_1-p(C_1-R_2,CPE_1)-p(C_2-p(C_3,R_3),R_4)",
#    "R_1-p(C_1-R_2,CPE_1)-p(C_2,R_3-p(C_3,R_4))",
#    "R_1-p(C_1-R_2,CPE_1)-p(C_2,CPE_2,R_3-p(C_3,R_4))",
#    "R_1-p(C_1-p(R_2,CPE_1),R_3)-p(C_2-p(C_3,R_4),R_5)",
#    "R_1-p(C_1-p(R_2,CPE_1),R_3)-p(C_2-p(C_3,R_4),R_5,R_6)",
#    "p(R_1,R_2)"
#]
#
#dict = test .|> conv_circuit 