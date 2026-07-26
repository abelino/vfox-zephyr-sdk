local cmd = require("cmd")

local archive = {}

function archive.extract(filename, cwd)
    local backends = {
        darwin = function(filename)
            return "tar -xf " .. filename
        end,
        linux = function(filename)
            return "tar -xf " .. filename
        end,
        windows = function(filename)
            return '7z x -y "' .. filename .. '"'
        end
    }

    local gen_command = backends[RUNTIME.osType]
        or error("no archive extraction implementation found for " .. RUNTIME.osType)

    cmd.exec(gen_command(filename), { cwd = cwd })
end

function archive.require_installed()
    local backends = {
        darwin = function()
            return "command -v tar"
        end,
        linux = function()
            return "command -v tar"
        end,
        windows = function()
            return "7z i"
        end
    }

    local gen_command = backends[RUNTIME.osType]
        or error("no archive extraction tool found for " .. RUNTIME.osType)

    cmd.exec(gen_command())
end

return archive
