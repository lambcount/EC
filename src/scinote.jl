using HTTP,JSON

const server_name = "http://titus.phchem.uni-due.de:3000"
const client_id = ""
const client_secret = ""
const redirect_uri = ""
const team_id = "AK Hasselbrink"
const project_id_femto_lab = "9"
const experiment_id_SEC = "53"
const task_id_EC = "297"





function auth_code()
    r = HTTP.request("GET",server_name*"/oauth/authorize?client_id=tim.laemmerzahl@uni-due.de&redirect_uri=$(server_name)&response_type=code")
    String(r.body)
    
end 

authorization_code = auth_code()

"""
token()

Get token with client_id, client_secret, authorization_code, and redirect_uri.
"""
function token()
    resp = HTTP.request("POST", SCINOTE_URL*"/oauth/token",
        ["grant_type" => "authorization_code",
        "client_id" => client_id,
        "client_secret" => client_secret,
        "code" => authorization_code,
        "redirect_uri" => redirect_uri
        ])
    body = String(resp.body)
    JSON.parse(body)
end

"""
refreshtoken()

Refresht the  token with client_id, client_secret, authorization_code, and redirect_uri.
"""
function refreshtoken()
    resp = HTTP.request("POST", SCINOTE_URL*"/oauth/token",
        ["grant_type" => "refresh_token",
        "client_id" => client_id,
        "client_secret" => client_secret,
        "refresh_token" => token,
        "redirect_uri" => redirect_uri
        ])
    body = String(resp.body)
    JSON.parse(body)
end


function api_status()
    r = HTTP.request("GET",server_name*"/api/status")
    JSON.parse(String(r.body))
end
