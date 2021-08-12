using HTTP,JSON,DataFrames

const SCINOTE_URL = "http://titus.phchem.uni-due.de:3000"
const client_id = "7vJ_9ypiSlFDLyWYoF_TGpceceDPxXFDnF01Wp3HPMo"
const client_secret = "RJkDV5Lc5ShILMXN2UiTFPnDw-nV1yT3xaPBGXB7w18"
const redirect_uri = ""
const team_id = "AK Hasselbrink"
const project_id_femto_lab = "9"
const experiment_id_SEC = "53"
const task_id_EC = "297"
const password = "1a2s3d4f"
const email = "tim.laemmerzahl@uni-due.de"
token_header = ["Content-Type" => "application/json"]


"""
Returns the Status of the Scinote API
"""
function api_status()
    r = HTTP.request("GET",SCINOTE_URL*"/api/status",header)
    JSON.parse(String(r.body))
end

"""
    api_running()
Returns if the API is running. 
"""
function api_running()
    r = HTTP.request("GET",SCINOTE_URL*"/api/health")
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
        resp = HTTP.request("POST", SCINOTE_URL*"/oauth/token",token_header,
        JSON.json(token_params))
        body = String(resp.body)
        JSON.parse(body)
    end
end




token_params = Dict(
    "grant_type" => "password",
    "client_id" => client_id,
    "client_secret" => client_secret,
    "email" => email,
    "password" => password
)


token_tim = token()["access_token"]
header(token) = Dict(
    "Content-Type" => "application/json",
    "Authorization" => "Bearer $token"
)



"""
    get_teams()
This function retrieves all teams user is member of.   
"""
function get_all_teams()
    if api_running() == true 
    
        r = HTTP.request("GET",SCINOTE_URL*"/api/v1/teams",header(token_tim))

        body = String(r.body)
        _body = JSON.parse(body)
        n_teams = length(_body["data"])

        teams = Dict("name" =>_body["data"][i]["attributes"]["name"],"id" => _body["data"][i]["id"] for i in 1:n_teams)
    end
end




"""
    get_projects(team::Int64)
This function retrieves all projects from the AK Hasselbrink team.
"""
function get_projects(team::Int64)
    if api_running() == true 
        resp=HTTP.request("GET",SCINOTE_URL*"/api/v1/teams/$(team)/projects",header)
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
        resp=HTTP.request("GET",SCINOTE_URL*"/api/v1/teams/$(team)/projects/$(project)/experiments",header)
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
        resp=HTTP.request("GET",SCINOTE_URL*"/api/v1/teams/$(team)/projects/$(project)/experiments/$(experiment)/tasks",header)
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
        resp=HTTP.request("GET",SCINOTE_URL*"/api/v1/teams/$(team)/projects/$(project)/experiments/$(experiment)/tasks/$(task)/protocols",header)
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
        resp=HTTP.request("GET",SCINOTE_URL*"/api/v1/teams/$(team)/projects/$(project)/experiments/$(experiment)/tasks/$(task)/protocols/$(protocol)/steps",header)
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
        resp=HTTP.request("GET",SCINOTE_URL*"/api/v1/teams/$(team)/projects/$(project)/experiments/$(experiment)/tasks/$(task)/protocols/$(protocol)/steps/$(step)/tables",header)
        body = String(resp.body)
        data=JSON.parse(JSON.parse(body)["data"][1]["attributes"]["contents"])["data"]

        param_names = [data[i][1] for i in 1:length(data) if data[i][1] !== nothing]
        param_values = [data[i][2] for i in 1:length(data) if data[i][1] !== nothing]
        param_units = [data[i][3] for i in 1:length(data) if data[i][1] !== nothing]

            return param_names,param_values,param_units
    end
end
