local Version = {}
Version.__index = Version

function Version.new(value)
    local major, minor, patch = value:match("^(%d+)%.(%d+)%.(%d+)$")
    assert(major, "Expected a valid version string: " .. value)

    return setmetatable({
        value = value,
        _major = tonumber(major),
        _minor = tonumber(minor),
        _patch = tonumber(patch),
    }, Version)
end

function Version:major()
    return self._major
end

function Version:minor()
    return self._minor
end

function Version:patch()
    return self._patch
end

function Version:__tostring()
    return self.value
end

function Version.__concat(left, right)
    return tostring(left) .. tostring(right)
end

function Version.__lt(a, b)
    if a:major() ~= b:major() then
        return a:major() < b:major()
    elseif a:minor() ~= b:minor() then
        return a:minor() < b:minor()
    else
        return a:patch() < b:patch()
    end
end

return Version
