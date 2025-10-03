const int LOD_COUNT = 11;
const float lod_thresholds[LOD_COUNT] = float[LOD_COUNT](
	0.02, 0.016, 0.012, 0.01, 0.008, 0.006, 0.004, 0.003, 0.002, 0.0015, 0.0012
);
const uint lods[LOD_COUNT] = uint[LOD_COUNT](64u, 96u, 128u, 144u, 192u, 256u, 384u, 512u, 768u, 1024u, 1536u);

// Snaps the given uv to an lod resolution based on the given 
// pixel_size in relation to uv coordinates.
vec2 get_lod_uv(vec2 uv, float pixel_size)
{
	if (pixel_size < 0.0008) { return uv; }

	uint lod;
	for (int i = 0; i < LOD_COUNT; ++i)
	{
    	if (pixel_size > lod_thresholds[i])
		{
			lod = lods[i];
			break;
		}
	}

	return floor(uv * float(lod)) / float(lod);
}