local cmd = require("cmd")
local info = require("info")
local strings = require("strings")
local version = require("version")

--- Returns all available Zephyr SDK versions
--- @param ctx table Context provided by vfox
--- @return table Available versions
function PLUGIN:BackendListVersions(ctx)
    local git_stdout = cmd.exec(
        "git ls-remote --tags --refs --sort=version:refname " .. info.url,
        { env = { GIT_TERMINAL_PROMPT = "0" }, timeout = 60 }
    )

    local lines = strings.split(strings.trim(git_stdout, "\n"), "\n")
    local versions = {}

    for _, line in ipairs(lines) do
        local release_raw = line:match("^%x+%s+refs/tags/v(%d+%.%d+%.%d+)%s*$")
        if release_raw ~= nil then
            local release = version.new(release_raw)
            if release > version.new("0.14.0") then
                versions[#versions + 1] = tostring(release)
            end
        end
    end

    return { versions = versions }
end
