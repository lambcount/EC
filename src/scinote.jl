using HTTP

const SCINOTE_URL = "http://titus.phchem.uni-due.de:3000"

"""
token(id::AbstractString,
      secret::AbstractString,
      username::AbstractString,
      password::AbstractString)

Get token with client_id, client_secret, username, and password.
"""
function token(username::AbstractString,
               password::AbstractString)
    resp = HTTP.request("POST", SCINOTE_URL*"/oauth/authorize",
        ["Authorization" => "Basic $auth"],
        "grant_type=password&username=$username&password=$password")
    body = String(resp.body)
    JSON.parse(body)["access_token"]
end

function auth_code()
    r = HTTP.request("GET",SCINOTE_URL*"/oauth/authorize")
end