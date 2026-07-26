local archive = require("archive")
local cmd = require("cmd")
local file = require("file")
local http = require("http")
local info = require("info")
local options = require("options")
local sha256 = require("sha256")
local strings = require("strings")
local version = require("version")

local OS_NAMES = {
    linux = "linux",
    darwin = "macos",
    windows = "windows"
}

local ARCH_NAMES = {
    amd64 = "x86_64",
    x86_64 = "x86_64",
    arm64 = "aarch64",
    aarch64 = "aarch64"
}

local priv = {}

--- Install a Zephyr SDK
--- @param ctx table Context provided by vfox
function PLUGIN:BackendInstall(ctx)
    sha256.require_installed()
    archive.require_installed()

    local os = assert(
        OS_NAMES[RUNTIME.osType],
        "Unsupported SDK host OS: " .. RUNTIME.osType)

    local arch = assert(
        ARCH_NAMES[RUNTIME.archType],
        "Unsupported SDK host architecture: " .. RUNTIME.archType)

    local ver = version.new(ctx.version)
    local opts = options.parse(ctx.options)
    local checksums = priv.fetch_bundle_checksums(ver)

    local sdk_asset, toolchain_asset =
        priv.assets(ctx.tool, ver, os, arch, opts)

    -- SDK installation
    local sdk_checksum = checksums[sdk_asset]

    assert(
        sdk_checksum,
        "SDK asset is unavailable: " .. sdk_asset)

    priv.try_download(
        sdk_asset,
        sdk_checksum,
        ver,
        ctx.download_path)

    file.move(
        file.join_path(ctx.download_path, "zephyr-sdk-" .. ver),
        ctx.install_path)

    if os == "linux" then
        priv.install_hosttools(ver, arch, ctx.install_path)
    end

    -- Toolchain installation
    local toolchain_checksum = checksums[toolchain_asset]

    assert(
        ctx.tool == "full" or toolchain_checksum,
        "Toolchain asset is unavailable: " .. tostring(toolchain_asset))

    if toolchain_asset ~= nil then
        priv.try_download(toolchain_asset, toolchain_checksum, ver, ctx.download_path)

        local toolchain = opts.llvm and "llvm" or ctx.tool
        local destination = ctx.install_path

        if ver:major() >= 1 and not opts.llvm then
            destination = file.join_path(destination, "gnu")
        end

        file.move(
            file.join_path(ctx.download_path, toolchain),
            file.join_path(destination, toolchain))
    end

    return {}
end

priv.fetch_bundle_checksums = function(ver)
    local checksums = {}

    local base_url = info.url .. "/releases/download/v" .. ver .. "/"
    local response = http.get({ url = base_url .. "sha256.sum" })
    assert(
        response.status_code == 200,
        "Could not fetch SDK checksums: HTTP " .. response.status_code)

    for _, line in ipairs(strings.split(strings.trim_space(response.body), "\n")) do
        local hash, name = line:match("^(%x+)%s+%*?([^%s]+)%s*$")
        checksums[name] = hash:lower()
    end

    return checksums
end

priv.assets = function(tool, ver, os, arch, options)
    local host = os .. "-" .. arch
    local llvm = options.llvm

    assert(
        not llvm or ver:major() >= 1,
        "LLVM bundles require SDK 1.0.0 or newer")

    -- SDK 0.16.0 switched from tar.gz/zip to tar.xz/7z.
    local extension
    if os == "windows" then
        extension = ver < version.new("0.16.0") and ".zip" or ".7z"
    else
        extension = ver < version.new("0.16.0") and ".tar.gz" or ".tar.xz"
    end

    local sdk_asset = "zephyr-sdk-" .. ver .. "_" .. host
    local toolchain_asset = nil

    if tool == "full" then
        if ver:major() >= 1 then
            sdk_asset = sdk_asset .. (llvm and "_llvm" or "_gnu")
        end
    else
        sdk_asset = sdk_asset .. "_minimal"
        toolchain_asset = "toolchain_"

        if ver:major() >= 1 then
            toolchain_asset = toolchain_asset .. (llvm and "llvm_" or "gnu_")
        end

        toolchain_asset = toolchain_asset .. host

        if not llvm then
            toolchain_asset = toolchain_asset .. "_" .. tool
        end

        toolchain_asset = toolchain_asset .. extension
    end

    return sdk_asset .. extension, toolchain_asset
end

priv.try_download = function(asset, hash, ver, download_path)
    print("Downloading " .. asset)

    local url = info.url .. "/releases/download/v" .. ver .. "/" .. asset
    local path = file.join_path(download_path, asset)

    http.download_file({ url = url }, path)

    print("Verifying " .. asset)
    local calculated_hash = sha256.sum(asset, download_path)
    assert(
        calculated_hash == hash,
        "SHA-256 mismatch for " .. asset .. " " .. hash .. " != " .. calculated_hash)

    print("Extracting " .. asset)
    archive.extract(asset, download_path)

    assert(os.remove(path))
end

priv.install_hosttools = function(ver, arch, install_path)
    local hosttools = ver:major() >= 1
        and file.join_path(install_path, "hosttools")
        or install_path
    local installer = "zephyr-sdk-" .. arch .. "-hosttools-standalone"

    local matches = file.glob(file.join_path(hosttools, installer .. "-*.sh"))
    assert(#matches == 1, "Expected one host-tools installer for " .. arch)

    local installer_path = file.join_path(hosttools, installer .. ".sh")

    file.move(matches[1], installer_path)
    cmd.exec("./" .. installer .. ".sh -y -d .", { cwd = hosttools })
    assert(os.remove(installer_path))
end
