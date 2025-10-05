const int LOD_COUNT = 11;
const float lod_thresholds[LOD_COUNT] = float[LOD_COUNT](
	0.02, 0.016, 0.012, 0.01, 0.008, 0.006, 0.004, 0.003, 0.002, 0.0012, 0.0008
);
const uint lods[LOD_COUNT] = uint[LOD_COUNT](16u, 32u, 64u, 96u, 128u, 144u, 192u, 256u, 384u, 512u, 768u);

// Snaps the given uv to an lod resolution based on the given 
// pixel_size in relation to uv coordinates.
vec3 get_lod_mask_pos(vec3 mask_pos, float pixel_size)
{
	if (pixel_size < 0.0012) { return mask_pos; }

	uint lod;
	for (int i = 0; i < LOD_COUNT; ++i)
	{
    	if (pixel_size > lod_thresholds[i])
		{
			lod = lods[i];
			break;
		}
	}
	
	return floor(mask_pos * float(lod)) / float(lod);
}