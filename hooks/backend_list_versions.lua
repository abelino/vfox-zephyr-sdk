local http = require("http")
local info = require("info")
local json = require("json")
local version = require("version")

--- Returns all available Zephyr SDK versions
--- @param ctx table Context provided by vfox
--- @return table Available versions
function PLUGIN:BackendListVersions(ctx)
    local versions = {}
    local page = 1
    local url = table.concat({
        "https://api.github.com/repos",
        info.org,
        info.name,
        "releases"
    }, "/")

    while true do
        local response = http.get({ url = url .. "?per_page=100&page=" .. page })

        assert(
            response.status_code == 200,
            "Could not fetch SDK releases: HTTP " .. response.status_code)

        local releases, error = json.decode(response.body)
        assert(releases, error)

        for _, release in ipairs(releases) do
            local release_raw = release.tag_name:match("^v(%d+%.%d+%.%d+)$")
            if not release.draft and not release.prerelease and release_raw ~= nil then
                local ver = version.new(release_raw)
                if ver > version.new("0.14.0") then
                    versions[#versions + 1] = tostring(ver)
                end
            end
        end

        if #releases < 100 then
            break
        end

        page = page + 1
    end

    table.sort(versions, function(a, b)
        return version.new(a) < version.new(b)
    end)

    return { versions = versions }
end
