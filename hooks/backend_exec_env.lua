local options = require("options")

--- Configure Zephyr builds to use an SDK installation.
--- @param ctx table Context provided by vfox
--- @return table Environment variables to apply when the SDK is active.
function PLUGIN:BackendExecEnv(ctx)
    local opts = options.parse(ctx.options)
    local toolchain = opts.llvm and "zephyr/llvm" or "zephyr"

    local env_vars = {
        { key = "ZEPHYR_SDK_INSTALL_DIR", value = ctx.install_path },
        { key = "ZEPHYR_TOOLCHAIN_VARIANT", value = toolchain },
    }

    return { env_vars = env_vars }
end
