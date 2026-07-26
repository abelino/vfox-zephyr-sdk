local cmd = require("cmd")

local sha256 = {}

function sha256.sum(filename, cwd)
    local backends = {
        darwin = function(filename)
            return "shasum -a 256 " .. filename
        end,
        linux = function(filename)
            return "sha256sum " .. filename
        end,
        windows = function(filename)
            return string.format(
                'powershell.exe -NoProfile -NonInteractive '
                    .. '-Command "(Get-FileHash -LiteralPath \'%s\' '
                    .. '-Algorithm SHA256 -ErrorAction Stop).Hash"',
                filename
            )
        end
    }

    local gen_command = backends[RUNTIME.osType]
        or error("no sha256 implementation found for " .. RUNTIME.osType)

    local hash =
        cmd.exec(gen_command(filename), { cwd = cwd }):match("^%s*(%x+)")

    return hash:lower()
end

function sha256.require_installed()
    local backends = {
        darwin = function()
            return "command -v shasum"
        end,
        linux = function()
            return "command -v sha256sum"
        end,
        windows = function()
            return 'powershell.exe -NoProfile -NonInteractive '
                .. '-Command "Get-Command Get-FileHash -ErrorAction Stop | Out-Null"'
        end
    }

    local gen_command = backends[RUNTIME.osType]
        or error("no sha256 tool found for " .. RUNTIME.osType)

    cmd.exec(gen_command())
end

return sha256
