PathUtil = {}


function PathUtil.findPath(sx, sy, sz, tx, ty, tz, levels, cellSize)

	local checked = { [sy] = { [sx] = { [sz] = true } } }
	local queue = { { ["x"] = sx, ["y"] = sy, ["z"] = sz, ["dir"] = 0, ["cost"] = 0, ["distance"] = PathUtil.getDistanceHeuristic({ ["x"] = sx, ["y"] = sy, ["z"] = sz }, { ["x"] = tx, ["y"] = ty, ["z"] = tz }), ["checked"] = checked, ["path"] = { { ["x"] = sx, ["y"] = sy, ["z"] = sz } } } }
	--local queue = { { ["x"] = sx, ["y"] = sy, ["z"] = sz, ["neighbours"] = PathUtil.getNeighbours(sx, sy, sz, cellSize, checked, levels), ["dir"] = 0, ["cost"] = 0, ["distance"] = PathUtil.getDistanceHeuristic({ ["x"] = sx, ["y"] = sy, ["z"] = sz }, { ["x"] = tx, ["y"] = ty, ["z"] = tz }), ["checked"] = checked, ["path"] = { { ["x"] = sx, ["y"] = sy, ["z"] = sz } } } }
	local target = { ["x"] = tx, ["y"] = ty, ["z"] = tz }

	return PathUtil.executeQueue(queue, target, levels, cellSize)

end


function PathUtil.executeQueue(queue, target, levels, cellSize)

	if #queue == 0 then return end

	table.sort(queue, PathUtil.sortQueueByCheapest)

	local point = table.remove(queue, 1)
	local x, y, z = point.x, point.y, point.z

	if x == target.x and y == target.y and z == target.z then return point.path, point.cost end

	local neighbours = PathUtil.getNeighbours(x, y, z, cellSize, point.checked, levels)

	for _, neighbour in pairs(neighbours) do

		local row = levels[neighbour.y].rows[neighbour.x]

		if row == nil then continue end

		local column = row.columns[neighbour.z]

		if not column then continue end

		local neighbourPath = table.clone(point.path, 5)
		local nx, ny, nz = neighbour.x, neighbour.y, neighbour.z
		
		table.insert(neighbourPath, { ["x"] = nx, ["y"] = ny, ["z"] = nz })

		if nx == target.x and ny == target.y and nz == target.z then return neighbourPath, point.cost end

		local dir = math.atan2(nx - x, nz - z)
		local cost = (dir == point.dir or #neighbourPath == 1) and 0 or (MathUtil.vector2Length(dir, point.dir) > 2 and 5) or 2
		--local neighbours = PathUtil.getNeighbours(nx, ny, nz, cellSize, point.checked, levels)

		table.insert(queue, { ["x"] = nx, ["y"] = ny, ["z"] = nz, ["dir"] = dir, ["cost"] = point.cost + cost, ["distance"] = PathUtil.getDistanceHeuristic(neighbour, target), ["checked"] = point.checked, ["path"] = neighbourPath })
		--table.insert(queue, { ["x"] = nx, ["y"] = ny, ["z"] = nz, ["neighbours"] = neighbours, ["dir"] = dir, ["cost"] = point.cost + cost + 4 - #neighbours, ["distance"] = PathUtil.getDistanceHeuristic(neighbour, target), ["checked"] = point.checked, ["path"] = neighbourPath })

	end

	return PathUtil.executeQueue(queue, target, levels, cellSize)

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


function PathUtil.getNeighbours(x, y, z, step, checked, levels)

	local neighbours = {}
	local ll, nl
	local posX, negX, posZ, negZ = roundNumber(x + step, 4), roundNumber(x - step, 4), roundNumber(z + step, 4), roundNumber(z - step, 4)

	for ly, level in pairs(levels) do

		local distance = math.abs(y - ly)

		if ly == y or distance > 0.25 then continue end

		if (ll == nil or math.abs(y - ll) > distance) and ly < y then
			if (level.rows[x] ~= nil and (level.rows[x].columns[negZ] ~= nil or level.rows[x].columns[posZ] ~= nil)) or (level.rows[negX] ~= nil and (level.rows[negX].columns[z] ~= nil or level.rows[negX].columns[negZ] ~= nil or level.rows[negX].columns[posZ] ~= nil)) or (level.rows[posX] ~= nil and (level.rows[posX].columns[z] ~= nil or level.rows[posX].columns[negZ] ~= nil or level.rows[posX].columns[posZ] ~= nil)) then ll = ly end
		end

		if (nl == nil or math.abs(y - nl) > distance) and ly > y then
			if (level.rows[x] ~= nil and (level.rows[x].columns[negZ] ~= nil or level.rows[x].columns[posZ] ~= nil)) or (level.rows[negX] ~= nil and (level.rows[negX].columns[z] ~= nil or level.rows[negX].columns[negZ] ~= nil or level.rows[negX].columns[posZ] ~= nil)) or (level.rows[posX] ~= nil and (level.rows[posX].columns[z] ~= nil or level.rows[posX].columns[negZ] ~= nil or level.rows[posX].columns[posZ] ~= nil)) then nl = ly end
		end

	end

	if checked[y] == nil then checked[y] = {} end
	neighbours = PathUtil.checkCells(x, y, z, step, checked[y], neighbours)

	if ll ~= nil then
		checked[ll] = checked[ll] or {}
		neighbours = PathUtil.checkCells(x, ll, z, step, checked[ll], neighbours)
	end

	if nl ~= nil then
		checked[nl] = checked[nl] or {}
		neighbours = PathUtil.checkCells(x, nl, z, step, checked[nl], neighbours)
	end

	return neighbours

end


function PathUtil.checkCells(x, y, z, step, checked, neighbours)

	local posX1 = roundNumber(x + step, 4)
	--local posX2 = roundNumber(x + step / 2, 4)
	local negX1 = roundNumber(x - step, 4)
	--local negX2 = roundNumber(x - step / 2, 4)
	local posZ1 = roundNumber(z + step, 4)
	--local posZ2 = roundNumber(z + step / 2, 4)
	local negZ1 = roundNumber(z - step, 4)
	--local negZ2 = roundNumber(z - step / 2, 4)

	if checked[posX1] == nil then checked[posX1] = {} end
	--if checked[posX2] == nil then checked[posX2] = {} end
	if checked[negX1] == nil then checked[negX1] = {} end
	--if checked[negX2] == nil then checked[negX2] = {} end
	if checked[x] == nil then checked[x] = {} end

	if checked[posX1][z] == nil then
		table.insert(neighbours, { ["x"] = posX1, ["y"] = y, ["z"] = z })
		checked[posX1][z] = true
	end

	if checked[negX1][z] == nil then
		table.insert(neighbours, { ["x"] = negX1, ["y"] = y, ["z"] = z })
		checked[negX1][z] = true
	end
	
	if checked[x][posZ1] == nil then
		table.insert(neighbours, { ["x"] = x, ["y"] = y, ["z"] = posZ1 })
		checked[x][posZ1] = true
	end

	if checked[x][negZ1] == nil then
		table.insert(neighbours, { ["x"] = x, ["y"] = y, ["z"] = negZ1 })
		checked[x][negZ1] = true
	end

	

	--if checked[posX2][posZ2] == nil then
		--table.insert(neighbours, { ["x"] = posX2, ["y"] = y, ["z"] = posZ2 })
		--checked[posX2][posZ2] = true
	--end

	--if checked[posX2][negZ2] == nil then
		--table.insert(neighbours, { ["x"] = posX2, ["y"] = y, ["z"] = negZ2 })
		--checked[posX2][negZ2] = true
	--end

	--if checked[negX2][posZ2] == nil then
		--table.insert(neighbours, { ["x"] = negX2, ["y"] = y, ["z"] = posZ2 })
		--checked[negX2][posZ2] = true
	--end

	--if checked[negX2][negZ2] == nil then
		--table.insert(neighbours, { ["x"] = negX2, ["y"] = y, ["z"] = negZ2 })
		--checked[negX2][negZ2] = true
	--end

	return neighbours

end