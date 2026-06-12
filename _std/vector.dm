
/datum/vector2 // "vector-derived types are not supported" - BYOND when I do /vector/proc
	var/x
	var/y

	New(var/x, var/y)
		. = ..()
		src.x = x
		src.y = y

	proc/get_copy()
		RETURN_TYPE(/datum/vector2)
		return new /datum/vector2(src.x, src.y)

	proc/add_vector(var/datum/vector2/vecB)
		RETURN_TYPE(/datum/vector2)
		return new /datum/vector2(src.x + vecB.x, src.y + vecB.y)

	/// Subtract this vector by another vector
	proc/subtract_vector(var/datum/vector2/vecB)
		RETURN_TYPE(/datum/vector2)
		return new /datum/vector2(src.x - vecB.x, src.y - vecB.y)

	proc/get_magnitude()
		return sqrt((x * x) + (y * y))

	proc/set_magnitude(var/mag)
		src.x = (src.x / src.get_magnitude()) * mag
		src.y = (src.y / src.get_magnitude()) * mag

	proc/multiply_magnitude(var/mult)
		src.x *= mult
		src.y *= mult

	proc/dot_product(var/datum/vector2/vecB)
		return (src.x * vecB.x) + (src.y * vecB.y)

	// Find the angle in polar coordinates (x-axis is pointed EAST, y-axis is pointed NORTH)
	proc/get_theta()
		return arctan(src.y / src.x)

	/// Returns the angle between two vectors in degrees. Between 0 - 180 degrees.
	proc/get_angle(var/datum/vector2/vecB)
		return arccos(src.dot_product(vecB) / (src.get_magnitude() * vecB.get_magnitude()))

	/// Returns a vector with the same magnitude pointed in the opposite direction
	proc/inverted()
		RETURN_TYPE(/datum/vector2)
		return new /datum/vector2(-src.x, -src.y)

	proc/normalized()
		RETURN_TYPE(/datum/vector2)
		var/mag = src.get_magnitude()
		return new /datum/vector2(src.x / mag, src.y / mag)

	/// Returns a vector with the same magnitude rotated by the inputted number of degrees
	proc/rotated(var/degrees)
		RETURN_TYPE(/datum/vector2)
		var/new_x = (cos(degrees) * src.x) - (sin(degrees) * src.y)
		var/new_y = (sin(degrees) * src.x) + (cos(degrees) * src.y)
		return new /datum/vector2(new_x, new_y)

	// Returns a vector reflected off a surface with a normal pointed towards the given direction.
	proc/reflected(var/datum/vector2/surface_normal)
		RETURN_TYPE(/datum/vector2)
		surface_normal = surface_normal.normalized()
		var/dot = src.dot_product(surface_normal)
		var/datum/vector2/reflection = new(surface_normal.x * 2 * dot, surface_normal.y * 2 * dot)
		reflection = src.subtract_vector(reflection)
		return reflection

	/// Return a vector reflected off a surface in the given direction
	proc/reflected_dir(var/dir)
		RETURN_TYPE(/datum/vector2)
		switch(dir)
			if(NORTH)
				if(src.y > 0)
					return new /datum/vector2(src.x, -src.y)
				return src.get_copy()
			if(SOUTH)
				if(src.y < 0)
					return new /datum/vector2(src.x, -src.y)
				return src.get_copy()
			if(EAST)
				if(src.x > 0)
					return new /datum/vector2(-src.x, src.y)
				return src.get_copy()
			if(WEST)
				if(src.x < 0)
					return new /datum/vector2(-src.x, src.y)
				return src.get_copy()
			if(NORTHEAST)
				return reflected(new /datum/vector2(-1, -1))
			if(NORTHWEST)
				return reflected(new /datum/vector2(1, -1))
			if(SOUTHEAST)
				return reflected(new /datum/vector2(-1, 1))
			if(SOUTHWEST)
				return reflected(new /datum/vector2(1, 1))

	proc/to_dir()
		var/theta = src.get_theta()
		switch(theta)
			if((45 - 22.5) to (45 + 22.5))
				return NORTHEAST
			if((90 - 22.5) to (90 + 22.5))
				return NORTH
			if((135 - 22.5) to (135 + 22.5))
				return NORTHWEST
			if((180 - 22.5) to (180 + 22.5))
				return WEST
			if((225 - 22.5) to (225 + 22.5))
				return SOUTHWEST
			if((270 - 22.5) to (270 + 22.5))
				return SOUTH
			if((315 - 22.5) to (315 + 22.5))
				return SOUTHEAST
			else
				return EAST

	proc/to_dir_cardinal()
		var/theta = src.get_theta()
		switch(theta)
			if(45 to 135)
				return NORTH
			if(135 to 225)
				return WEST
			if(225 to 315)
				return SOUTH
			else
				return EAST
