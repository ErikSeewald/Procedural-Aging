shader_type canvas_item;

uniform float scale : hint_range(0.1, 100.0) = 12.0;
uniform float jitter : hint_range(0.0, 1.0) = 1.0;
uniform bool color_cells = false;
uniform float edge_thickness : hint_range(0.0, 0.2) = 0.02;

float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
    return vec2(hash12(p), hash12(p + 17.0));
}

vec3 cell_color_from_id(vec2 id)
{
    return vec3(hash12(id + 0.0), hash12(id + 37.0), hash12(id + 73.0));
}

void fragment()
{
    vec2 uv = UV * scale;

    vec2 base = floor(uv);
    vec2 f = fract(uv);

    float d1 = 1e9;
    float d2 = 1e9;
    vec2 best_id = vec2(0.0);

    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 cell = vec2(float(i), float(j));
            vec2 cell_id = base + cell;

            vec2 r = hash22(cell_id);
            vec2 feature = cell + (r - 0.5) * jitter + 0.5;

            vec2 diff = feature - f;
            float dist2 = dot(diff, diff);

            if (dist2 < d1) {
                d2 = d1;
                d1 = dist2;
                best_id = cell_id;
            } else if (dist2 < d2) {
                d2 = dist2;
            }
        }
    }

    float F1 = sqrt(d1);
    float F2 = sqrt(d2);

    float edge_w = edge_thickness / max(scale, 0.0001);
    float lines = 1.0 - smoothstep(0.0, edge_w, F2 - F1);

    vec3 base_col = color_cells ? cell_color_from_id(best_id) : vec3(F1);
    vec3 final_col = mix(base_col, vec3(0.0), lines);

    COLOR = vec4(final_col, 1.0);
}

