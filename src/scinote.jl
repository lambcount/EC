using HTTP,JSON,DataFrames

const server_name = "http://titus.phchem.uni-due.de:3000"
const client_id = "mp1YyqtADkI8wHqbRyAEsqdr3hALhjRqYgsw5T5snM8"
const client_secret = "mmtmPd9ctROk83hKk21qECDTtlwzsbhMF7pHob601LY"
const redirect_uri = ""
const team_id = "AK Hasselbrink"
const project_id_femto_lab = "9"
const experiment_id_SEC = "53"
const task_id_EC = "297"

const server_name_home = "http://192.168.178.58:3000"
const client_id_home = "vBNWRS3xi_d4QMm7McGde7kJhmE85ssLYes_7iab_Tw"
const client_secret_home = "ox1WawrGtiQgcRRaAAC5vAHDvlY8D_oOs0uoneHhk4k"


#a=HTTP.post("http://titus.phchem.uni-due.de:3000/oauth/token?grant_type=password&email=tim.laemmerzahl@uni-due.de&password=1a2s3d4f&client_id=mp1YyqtADkI8wHqbRyAEsqdr3hALhjRqYgsw5T5snM8&client_secret=mmtmPd9ctROk83hKk21qECDTtlwzsbhMF7pHob601LY")

#function auth_code()
#    r = HTTP.request("GET",server_name*"/oauth/authorize?client_id=mp1YyqtADkI8wHqbRyAEsqdr3hALhjRqYgsw5T5snM8&redirect_uri=&response_type=code")
#    String(r.body)
#    
#end 

#authorization_code = auth_code()


"""
    api_running()
Returns if the API is running. 
"""
function api_running()
    r = HTTP.request("GET",server_name_home*"/api/health")
    resp = String(r.body)
    if (resp == "RUNNING") == true
        return true
    else
        error("The API seems not to be running. Get Request returns $(resp)")
    end
end

"""
token()

Get token with client_id, client_secret, authorization_code, and redirect_uri.
"""
function token()
    if api_running() == true
        header = Dict("Content-Type"=> "application/json")
        params = Dict(
            "grant_type" => "password",
            "email" => "tim.laemmerzahl@uni-due.de",
            "password"=> "1a2s3d4f",
            "client_id" => client_id_home,
            "client_secret" => client_secret_home
        )
        resp = HTTP.request("POST", server_name_home*"/oauth/token",header,JSON.json(params))
        body = String(resp.body)
        return JSON.parse(body)["access_token"]
    end
end

access_token = token()
header= Dict("Authorization"=> "Bearer $(access_token)")


"""
Returns the Status of the Scinote API
"""
function api_status()
    r = HTTP.request("GET",server_name_home*"/api/status",header)
    JSON.parse(String(r.body))
end


"""
    get_teams()
This function retrieves all teams user is member of.   
"""
function get_teams()
    if api_running() == true 
        resp= HTTP.request("GET",server_name_home*"/api/v1/teams",header)
        body = String(resp.body)
        data = JSON.parse(body)["data"]            
    end
end

"""
    get_projects(team::Int64)
This function retrieves all projects from the AK Hasselbrink team.
"""
function get_projects(team::Int64)
    if api_running() == true 
        resp=HTTP.request("GET",server_name_home*"/api/v1/teams/$(team)/projects",header)
        body = String(resp.body)
        data=JSON.parse(body)["data"]
    end 
end

"""
    get_experiments(project::Int64,team::Int64)
This function retrieves all experiments from the specified project
"""
function get_experiments(team::Int64,project::Int64)
    if api_running() == true 
        resp=HTTP.request("GET",server_name_home*"/api/v1/teams/$(team)/projects/$(project)/experiments",header)
        body = String(resp.body)
        data=JSON.parse(body)["data"] 
    end
end

"""
    get_tasks(team::Int64,project::Int64,experiment::Int64)
This function retrieves all tasks from a specific experiment. 
"""
function get_tasks(team::Int64,project::Int64,experiment::Int64)
    if api_running() == true 
        resp=HTTP.request("GET",server_name_home*"/api/v1/teams/$(team)/projects/$(project)/experiments/$(experiment)/tasks",header)
        body = String(resp.body)
        data=JSON.parse(body)["data"]
    end
end


"""
    get_protocols(team::Int64,project::Int64,experiment::Int64,task::Int64)
This function retrieves all protocols from a specific experiment. 
"""
function get_protocols(team::Int64,project::Int64,experiment::Int64,task::Int64)
    if api_running() == true 
        resp=HTTP.request("GET",server_name_home*"/api/v1/teams/$(team)/projects/$(project)/experiments/$(experiment)/tasks/$(task)/protocols",header)
        body = String(resp.body)
        data=JSON.parse(body)["data"]
    end
end


"""
    get_steps(team::Int64,project::Int64,experiment::Int64,task::Int64,protocol::Int64)
This function retrieves all steps from a specific protocol. 
"""
function get_steps(team::Int64,project::Int64,experiment::Int64,task::Int64,protocol::Int64)
    if api_running() == true 
        resp=HTTP.request("GET",server_name_home*"/api/v1/teams/$(team)/projects/$(project)/experiments/$(experiment)/tasks/$(task)/protocols/$(protocol)/steps",header)
        body = String(resp.body)
        data=JSON.parse(body)["data"]
    end
end

"""
    get_step_table(team::Int64,project::Int64,experiment::Int64,task::Int64,protocol::Int64,step::Int64)
This function retrieves the table from specific step. 
Empty cells will be ignored. Be sure to have a proper 
"""
function get_step_table(team::Int64,project::Int64,experiment::Int64,task::Int64,protocol::Int64,step::Int64)
    if api_running() == true
        resp=HTTP.request("GET",server_name_home*"/api/v1/teams/$(team)/projects/$(project)/experiments/$(experiment)/tasks/$(task)/protocols/$(protocol)/steps/$(step)/tables",header)
        body = String(resp.body)
        data=JSON.parse(JSON.parse(body)["data"][1]["attributes"]["contents"])["data"]

        param_names = [data[i][1] for i in 1:length(data) if data[i][1] !== nothing]
        param_values = [data[i][2] for i in 1:length(data) if data[i][1] !== nothing]
        param_units = [data[i][3] for i in 1:length(data) if data[i][1] !== nothing]

            return param_names,param_values,param_units
    end
end