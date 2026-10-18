--!strict
--[[
	Updates the package version in every file that records it.

	Usage:
		pesde run bump -- 3.4.1
		lune run scripts/bump_version.luau 3.4.1
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local rawVersion = process.args[1]
if not rawVersion then
	error("Provide a version, for example: pesde run bump -- 3.4.1")
end

local version = string.match(rawVersion, "^v?(%d+%.%d+%.%d+)$")
if not version then
	error(`'{rawVersion}' is not a version of the form MAJOR.MINOR.PATCH`)
end

local currentVersion = string.match(fs.readFile("pesde.toml"), 'version = "(%d+%.%d+%.%d+)"')
if not currentVersion then
	error("Could not read the current version from pesde.toml")
end

local targets = {
	{
		path = "pesde.toml",
		pattern = 'version = "%d+%.%d+%.%d+"',
		replacement = `version = "{version}"`,
	},
	{
		path = "wally.toml",
		pattern = 'version = "%d+%.%d+%.%d+"',
		replacement = `version = "{version}"`,
	},
	{
		path = "src/VERSION.lua",
		pattern = 'VERSION%.appVersion = "v%d+%.%d+%.%d+"',
		replacement = `VERSION.appVersion = "v{version}"`,
	},
}

local changed = {}
for _, target in targets do
	local contents = fs.readFile(target.path)
	local newContents, count = string.gsub(contents, target.pattern, target.replacement)
	if count ~= 1 then
		error(`Expected one version in {target.path}, found {count}`)
	end
	if newContents ~= contents then
		fs.writeFile(target.path, newContents)
		table.insert(changed, target.path)
	end
end

if #changed == 0 then
	print(`Already at {version}`)
else
	print(`Bumped {currentVersion} -> {version}`)
	for _, path in changed do
		print(`  {path}`)
	end
end
