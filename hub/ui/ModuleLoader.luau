--[[
	Filesystem require shim for vendored Roblox UI packages (Fusion, OnyxUI, Iris, etc.).
]]

return function(deps)
	deps = type(deps) == "table" and deps or {}
	local readSource = deps.readSource
	local loadChunk = deps.loadChunk
	local rootPrefix = deps.root or "vendor"
	local extensions = deps.extensions or { ".luau", ".lua" }

	if type(readSource) ~= "function" or type(loadChunk) ~= "function" then
		error("ModuleLoader requires readSource and loadChunk", 0)
	end

	local cache = {}
	local loading = {}
	local scriptNodes = {}

	local function normalize(path)
		path = tostring(path or ""):gsub("\\", "/"):gsub("/+", "/")
		path = path:gsub("^/+", "")
		if path:sub(-1) == "/" then
			path = path:sub(1, -2)
		end
		return path
	end

	local function dirname(path)
		path = normalize(path)
		local parent = path:match("^(.*)/[^/]+$")
		return parent or ""
	end

	local function joinPath(dir, rel)
		dir = normalize(dir)
		rel = normalize(rel)
		if rel == "" then
			return dir
		end
		if dir == "" then
			return rel
		end
		return dir .. "/" .. rel
	end

	local function resolveRelative(baseDir, rel)
		rel = rel:gsub("^%.%/", "")
		local dir = dirname(baseDir)
		for segment in rel:gmatch("[^/]+") do
			if segment == ".." then
				dir = dirname(dir)
			elseif segment ~= "." and segment ~= "" then
				dir = joinPath(dir, segment)
			end
		end
		return dir
	end

	local function withRoot(path)
		path = normalize(path)
		if path:find("^" .. rootPrefix .. "/") then
			return path
		end
		return joinPath(rootPrefix, path)
	end

	local function scriptName(path)
		local name = path:match("([^/]+)$") or path
		return (name:gsub("%..+$", ""))
	end

	local function getScript(path)
		path = normalize(path)
		if scriptNodes[path] then
			return scriptNodes[path]
		end
		local parentPath = dirname(path)
		local parent = parentPath ~= "" and getScript(parentPath) or nil
		local node = {
			Name = scriptName(path),
			Parent = parent,
			_path = path,
		}
		setmetatable(node, {
			__index = function(_, key)
				if key == "Parent" then
					return parent
				elseif key == "Name" then
					return node.Name
				elseif key == "_path" then
					return path
				else
					return getScript(joinPath(path, key))
				end
			end,
		})
		scriptNodes[path] = node
		return node
	end

	local function readModuleSource(path)
		path = withRoot(path)
		local candidates = { path }
		local leaf = path:match("([^/]+)$")
		if leaf and leaf:lower() ~= leaf then
			table.insert(candidates, (path:gsub(leaf .. "$", leaf:lower())))
		elseif leaf then
			table.insert(candidates, (path:gsub(leaf .. "$", leaf:sub(1, 1):upper() .. leaf:sub(2))))
		end
		for _, candidatePath in ipairs(candidates) do
			local direct = readSource(candidatePath)
			if type(direct) == "string" and direct ~= "" then
				return direct, candidatePath
			end
			for _, ext in ipairs(extensions) do
				local candidate = candidatePath .. ext
				local body = readSource(candidate)
				if type(body) == "string" and body ~= "" then
					return body, candidate
				end
			end
			local initPath = joinPath(candidatePath, "init")
			for _, ext in ipairs(extensions) do
				local candidate = initPath .. ext
				local body = readSource(candidate)
				if type(body) == "string" and body ~= "" then
					return body, candidate
				end
			end
		end
		return nil, path
	end

	local currentPath = ""

	local function requireModule(path)
		path = normalize(path)
		if cache[path] ~= nil then
			return cache[path]
		end
		if loading[path] then
			error("circular require: " .. path, 0)
		end
		loading[path] = true

		local source, resolvedPath = readModuleSource(path)
		if not source then
			loading[path] = nil
			error("module not found: " .. path, 0)
		end

		local scriptObj = getScript(resolvedPath)
		local previousPath = currentPath
		currentPath = resolvedPath

		local env = {
			script = scriptObj,
			require = function(mod)
				if type(mod) == "string" then
					if mod:sub(1, 2) == "./" or mod:sub(1, 3) == "../" then
						return requireModule(resolveRelative(currentPath, mod))
					end
					return requireModule(mod)
				end
				if type(mod) == "table" then
					if mod._path then
						return requireModule(mod._path)
					end
					if mod.Name and mod.Parent then
						local cursor = mod
						local parts = {}
						while cursor do
							table.insert(parts, 1, cursor.Name)
							cursor = cursor.Parent
						end
						local rel = table.concat(parts, "/")
						return requireModule(joinPath(rootPrefix, rel))
					end
				end
				error("invalid require argument", 0)
			end,
		}
		setmetatable(env, { __index = _G })

		local fn = loadChunk(source, "@Alleral/" .. resolvedPath)
		if setfenv then
			pcall(setfenv, fn, env)
		end
		local ok, result = pcall(fn)
		currentPath = previousPath
		loading[path] = nil
		if not ok then
			error(result, 0)
		end
		cache[path] = result
		cache[resolvedPath] = result
		return result
	end

	return {
		require = requireModule,
		load = requireModule,
	}
end
