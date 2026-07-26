local options = {}

function options.try_parse(values)
    if values == nil then
        values = {}
    elseif type(values) ~= "table" then
        return nil, "Expected plugin options to be a table"
    end

    local llvm = values.llvm
    if llvm == nil or llvm == false or llvm == "false" then
        llvm = false
    elseif llvm == true or llvm == "true" then
        llvm = true
    else
        return nil, "Option 'llvm' must be true or false"
    end

    return { llvm = llvm }, nil
end

function options.parse(values)
    local opts, error = options.try_parse(values)

    assert(error == nil, error)

    return opts
end

return options
