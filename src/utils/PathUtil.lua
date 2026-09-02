PathUtil = {}


function PathUtil.findPath(sx, sy, sz, tx, ty, tz, levels, executor)

	local checked = { [sy] = { [sx] = { [sz] = true } } }
	local target = { ["x"] = tx, ["y"] = ty, ["z"] = tz }
	local queue = { { ["x"] = sx, ["y"] = sy, ["z"] = sz, ["dir"] = 0, ["cost"] = 0, ["distance"] = PathUtil.getDistanceHeuristic({ ["x"] = sx, ["y"] = sy, ["z"] = sz }, target), ["checked"] = checked, ["path"] = { { ["x"] = sx, ["y"] = sy, ["z"] = sz } } } }

	return PathUtil.executeQueue(queue, target, levels, executor)

end

-- 62 47.0053 29 => 56 50.3008 65


function PathUtil.executeQueue(queue, target, levels, executor)

	if #queue == 0 then return end

	table.sort(queue, PathUtil.sortQueueByCheapest)

	local job = table.remove(queue, 1)
	local x, y, z = job.x, job.y, job.z
	local tx, ty, tz = target.x, target.y, target.z

	if x == tx and y == ty and z == tz then return job.path, job.cost end

	local neighbours = PathUtil.getNeighbours(x, y, z, job.checked, levels)

	for _, neighbour in pairs(neighbours) do

		local nx, ny, nz = neighbour.x, neighbour.y, neighbour.z
		local row = levels[ny].rows[nx]

		if row == nil then continue end

		local column = row[nz]

		if not column then continue end

		local neighbourPath = table.clone(job.path, 5)
		table.insert(neighbourPath, { ["x"] = nx, ["y"] = ny, ["z"] = nz })

		if nx == tx and ny == ty and nz == tz then return neighbourPath, job.cost end

		local dir = math.atan2(nx - x, nz - z)
		local cost = (dir == job.dir or #neighbourPath == 1) and 0 or (MathUtil.vector2Length(dir, job.dir) > 2 and 5) or 2
		
		table.insert(queue, { ["x"] = nx, ["y"] = ny, ["z"] = nz, ["dir"] = dir, ["cost"] = job.cost + cost, ["distance"] = PathUtil.getDistanceHeuristic(neighbour, target), ["checked"] = job.checked, ["path"] = neighbourPath })
		
	end

	return PathUtil.executeQueue(queue, target, levels, executor)

end


function PathUtil.sortQueueByCheapest(a, b)

	local f1 = a.cost + a.distance
	local f2 = b.cost + b.distance

	if f1 == f2 then return #a.path < #b.path end

	return f1 < f2

end


function PathUtil.getDistanceHeuristic(current, target)

	local dx = current.x - target.x
    local dy = current.y - target.y
    local dz = current.z - target.z

    local horizontal = math.sqrt(dx*dx + dz*dz)
    local vertical   = math.abs(dy)

    return horizontal + vertical

end

function PathUtil.getNeighbours(x, y, z, checked, levels)

	local neighbours = {}
	local ll, nl
	local posX, negX, posZ, negZ = x + 1, x - 1, z + 1, z - 1

	for ly, level in pairs(levels) do

		local distance = math.abs(y - ly)

		if ly == y or distance > 0.25 then continue end

		if (ll == nil or math.abs(y - ll) > distance) and ly < y then
			if (level.rows[x] ~= nil and (level.rows[x][negZ] ~= nil or level.rows[x][posZ] ~= nil)) or (level.rows[negX] ~= nil and (level.rows[negX][z] ~= nil or level.rows[negX][negZ] ~= nil or level.rows[negX][posZ] ~= nil)) or (level.rows[posX] ~= nil and (level.rows[posX][z] ~= nil or level.rows[posX][negZ] ~= nil or level.rows[posX][posZ] ~= nil)) then ll = ly end
		end

		if (nl == nil or math.abs(y - nl) > distance) and ly > y then
			if (level.rows[x] ~= nil and (level.rows[x][negZ] ~= nil or level.rows[x][posZ] ~= nil)) or (level.rows[negX] ~= nil and (level.rows[negX][z] ~= nil or level.rows[negX][negZ] ~= nil or level.rows[negX][posZ] ~= nil)) or (level.rows[posX] ~= nil and (level.rows[posX][z] ~= nil or level.rows[posX][negZ] ~= nil or level.rows[posX][posZ] ~= nil)) then nl = ly end
		end

	end

	if checked[y] == nil then checked[y] = {} end
	neighbours = PathUtil.checkCells(x, y, z, checked[y], neighbours)

	if ll ~= nil then
		checked[ll] = checked[ll] or {}
		neighbours = PathUtil.checkCells(x, ll, z, checked[ll], neighbours)
	end

	if nl ~= nil then
		checked[nl] = checked[nl] or {}
		neighbours = PathUtil.checkCells(x, nl, z, checked[nl], neighbours)
	end

	return neighbours

end


function PathUtil.checkCells(x, y, z, checked, neighbours)

	local posX, negX, posZ, negZ = x + 1, x - 1, z + 1, z - 1

	if checked[posX] == nil then checked[posX] = {} end
	if checked[negX] == nil then checked[negX] = {} end
	if checked[x] == nil then checked[x] = {} end

	if checked[posX][z] == nil then
		table.insert(neighbours, { ["x"] = posX, ["y"] = y, ["z"] = z })
		checked[posX][z] = true
	end

	if checked[negX][z] == nil then
		table.insert(neighbours, { ["x"] = negX, ["y"] = y, ["z"] = z })
		checked[negX][z] = true
	end
	
	if checked[x][posZ] == nil then
		table.insert(neighbours, { ["x"] = x, ["y"] = y, ["z"] = posZ })
		checked[x][posZ] = true
	end

	if checked[x][negZ] == nil then
		table.insert(neighbours, { ["x"] = x, ["y"] = y, ["z"] = negZ })
		checked[x][negZ] = true
	end

	return neighbours

end