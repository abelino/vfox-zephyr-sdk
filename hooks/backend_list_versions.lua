local cmd = require("cmd")
local info = require("info")
local strings = require("strings")

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
        local release_version = line:match("^%x+%s+refs/tags/v(%d+%.%d+%.%d+)%s*$")
        if release_version then
            versions[#versions + 1] = release_version
        end
    end

    return { versions = versions }
end
