shader_type canvas_item;
uniform float noise_opacity : hint_range(0.0, 1.0) = 0.35;
uniform float noise_speed = 5.0;
uniform float static_noise_intensity : hint_range(0.0, 1.0) = 0.06;
// PSX crunch messes up your screen real good
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
// rez controls - don't push too high or it'll look clean we don't want that lol
uniform int resolution_x = 320; // psx standard
uniform int resolution_y = 240; 
uniform int color_bit_depth = 4; // 16 colors per channel feels right
// dithering + palette quantization (ported from the palette shader)
uniform bool dithering = true;
uniform int dithering_size : hint_range(1, 16) = 2;
uniform sampler2D palette;
uniform int quantization_level : hint_range(2, 16) = 16;
uniform float mix_amount : hint_range(0.0, 1.0) = 0.5; // 0 = original crushed colors, 1 = full palette quantization
// jitter section - this is where the magic happens
uniform float jitter_amount = 0.008;
uniform float jitter_speed = 1.2;
uniform float jitter_frequency = 180.0;
// chromatic mess & vignette
uniform float chromatic_aberration_strength : hint_range(0.0, 0.1) = 0.015;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.8;
uniform float vignette_radius : hint_range(0.0, 2.0) = 0.9;
vec2 random(vec2 uv){
    uv = vec2(dot(uv, vec2(127.1,311.7)),
              dot(uv, vec2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}
float noise(vec2 uv){
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);
    vec2 blur = smoothstep(0.0, 1.0, uv_fract);
    return mix(
        mix(dot(random(uv_index + vec2(0.0,0.0)), uv_fract),
            dot(random(uv_index + vec2(1.0,0.0)), uv_fract - vec2(1.0,0.0)), blur.x),
        mix(dot(random(uv_index + vec2(0.0,1.0)), uv_fract - vec2(0.0,1.0)),
            dot(random(uv_index + vec2(1.0,1.0)), uv_fract - vec2(1.0,1.0)), blur.x),
        blur.y
    ) * 0.5 + 0.5;
}
float hash(vec2 p){
    return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453123);
}
int dithering_pattern(ivec2 fragcoord) {
	const int pattern[] = {
		-4, +0, -3, +1,
		+2, -2, +3, -1,
		-3, +1, -4, +0,
		+3, -1, +2, -2
	};
	int x = fragcoord.x % 4;
	int y = fragcoord.y % 4;
	return pattern[y * 4 + x] * dithering_size;
}
float color_distance(vec3 a, vec3 b) {
	vec3 diff = a - b;
	return dot(diff, diff);
}
vec3 quantize_color(vec3 color, int levels) {
	if (levels <= 1) return vec3(0.0);
	float step = 1.0 / float(levels - 1);
	return round(color / step) * step;
}
vec2 psx_jitter(vec2 uv){
    float t = floor(TIME * jitter_speed * 8.0) / 8.0; // snap time
    
    // horizontal shake per scanline
    float h_shake = hash(vec2(floor(uv.y * jitter_frequency), t)) - 0.5;
    h_shake *= jitter_amount * 0.75;
    
    // vertical wobble
    float v_shake = hash(vec2(floor(uv.x * jitter_frequency * 0.4), t)) - 0.5;
    v_shake *= jitter_amount * 0.35;
    
    // micro-shake for crunchy feel
    float micro = hash(uv * 600.0 + t) - 0.5;
    micro *= jitter_amount * 0.1;
    
    return uv + vec2(h_shake + micro, v_shake + micro);
}
void fragment(){
    // snap to pixel grid
    vec2 px = vec2(1.0 / float(resolution_x), 1.0 / float(resolution_y));
    vec2 uv = floor(SCREEN_UV / px) * px + px * 0.5;
    
    uv = psx_jitter(uv); // apply that sweet jitter
    
    vec3 col;
    if(chromatic_aberration_strength > 0.001){
        vec2 offset = (uv - 0.5) * chromatic_aberration_strength;
        col.r = texture(SCREEN_TEXTURE, uv + offset).r;
        col.g = texture(SCREEN_TEXTURE, uv).g;
        col.b = texture(SCREEN_TEXTURE, uv - offset).b;
    }else{
        col = texture(SCREEN_TEXTURE, uv).rgb;
    }
    
    // crush colors
    float levels = pow(2.0, float(color_bit_depth));
    col = floor(col * levels) / levels;
    
    // vignette
    if(vignette_strength > 0.0){
        float dist = distance(SCREEN_UV, vec2(0.5));
        float vignette = 1.0 - vignette_strength * smoothstep(vignette_radius * 0.5, vignette_radius, dist);
        col *= vignette;
    }
    
    // Colored dithering + palette quantization (ported from the palette shader)
    {
        ivec2 texel_coord = ivec2(floor(SCREEN_UV * vec2(float(resolution_x), float(resolution_y))));
        vec3 quant_color = col;
        if(dithering){
            int dither = dithering_pattern(texel_coord);
            quant_color += vec3(float(dither) / 255.0);
        }
        quant_color = clamp(quant_color, 0.0, 1.0);
        quant_color = quantize_color(quant_color, quantization_level);

        int palette_size = 16;
        float closest_distance = 9999.0;
        vec3 closest_color = vec3(0.0);
        for (int i = 0; i < palette_size; i++) {
            float u = float(i) / float(palette_size - 1);
            vec3 palette_color = texture(palette, vec2(u, 0.0)).rgb;
            float dist = color_distance(quant_color, palette_color);
            if (dist < closest_distance) {
                closest_distance = dist;
                closest_color = palette_color;
            }
        }
        col = mix(col, closest_color, mix_amount);
    }
	// Animated VHS-style noise
	if(noise_opacity > 0.0){
	    float n = smoothstep(
	        0.4,
	        0.5,
	        noise(uv * vec2(2.0, 200.0) + vec2(10.0, TIME * noise_speed))
	    );
	    col = mix(col, col + vec3(n), noise_opacity);
	}
	// Static grain
	if(static_noise_intensity > 0.0){
	    float grain = clamp(
	        random(
	            floor(uv * vec2(float(resolution_x), float(resolution_y)))
	            + fract(TIME)
	        ).x,
	        0.0,
	        1.0
	    );
	    col += grain * static_noise_intensity;
	}
    
    COLOR = vec4(col, 1.0);
}
