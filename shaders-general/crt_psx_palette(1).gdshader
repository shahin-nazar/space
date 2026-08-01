shader_type canvas_item;

uniform bool shader_enabled = true;
uniform sampler2D palette;
uniform bool dithering = false;
uniform int dithering_size : hint_range(1, 16) = 2;
uniform int resolution_scale : hint_range(1, 64) = 2;
uniform int quantization_level : hint_range(2, 16) = 16;
uniform sampler2D SCREEN_TEXTURE:hint_screen_texture,filter_linear;
uniform float mix_amount : hint_range(0.0, 1.0) = 0.5; // 0 = original game colors, 1 = full palette quantization

// ---- PSX/CRT extras pulled in from shader 1 ----
uniform bool pixelate = true;
uniform vec2 resolution = vec2(640.0, 480.0);

uniform int color_bit_depth = 4; // bits per channel
uniform float dither_strength : hint_range(0.0, 0.1) = 0.03;

uniform bool roll = true;
uniform float roll_speed = 8.0;
uniform float roll_size : hint_range(0.0, 100.0) = 15.0;
uniform float roll_variation : hint_range(0.1, 5.0) = 1.8;
uniform float distort_intensity : hint_range(0.0, 0.2) = 0.05;

uniform float noise_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float noise_speed = 5.0;

uniform float static_noise_intensity : hint_range(0.0, 1.0) = 0.06;

uniform float aberration : hint_range(-1.0, 1.0) = 0.03;
uniform bool discolor = true;

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

// ---- helpers for the ported noise/roll effects ----
float hash(vec2 p){
    return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453123);
}

vec2 random(vec2 uv){
    uv = vec2(dot(uv, vec2(127.1,311.7)), dot(uv, vec2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);
    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix(
        mix(dot(random(uv_index + vec2(0.0,0.0)), uv_fract - vec2(0.0,0.0)),
            dot(random(uv_index + vec2(1.0,0.0)), uv_fract - vec2(1.0,0.0)), blur.x),
        mix(dot(random(uv_index + vec2(0.0,1.0)), uv_fract - vec2(0.0,1.0)),
            dot(random(uv_index + vec2(1.0,1.0)), uv_fract - vec2(1.0,1.0)), blur.x),
        blur.y
    ) * 0.5 + 0.5;
}

void fragment() {
	vec4 final_color;

	// Pixelation runs first and unconditionally at full (100%) strength --
	// it is NOT part of the aberration/roll mix amount below.
	vec2 uv = UV;
	if (pixelate) {
		uv = (floor(UV * resolution) + 0.5) / resolution;
	}

	if (!shader_enabled) {
		final_color = texture(SCREEN_TEXTURE, uv);
	} else {
		vec2 tex_size = vec2(textureSize(SCREEN_TEXTURE, 0));
		if (tex_size.x <= 0.0 || tex_size.y <= 0.0) {
			final_color = vec4(0.0);
		} else {
			ivec2 texel_coord = ivec2(floor(uv * tex_size / float(resolution_scale)));
			vec3 color = texelFetch(SCREEN_TEXTURE, texel_coord * resolution_scale, 0).rgb;
			if (dithering) {
				int dither = dithering_pattern(texel_coord);
				color += vec3(float(dither) / 255.0);
			}
			color = clamp(color, 0.0, 1.0);
			color = quantize_color(color, quantization_level);
			int palette_size = 16;
			float closest_distance = 9999.0;
			vec4 closest_color = vec4(0.0);
			for (int i = 0; i < palette_size; i++) {
				float u = float(i) / float(palette_size - 1);
				vec3 palette_color = texture(palette, vec2(u, 0.0)).rgb;
				float dist = color_distance(color, palette_color);
				if (dist < closest_distance) {
					closest_distance = dist;
					closest_color = vec4(palette_color, 1.0);
				}
			}
			vec3 original_color = texture(SCREEN_TEXTURE, uv).rgb;
			final_color = vec4(mix(original_color, closest_color.rgb, mix_amount), 1.0);
		}

		// ---- PSX/CRT extras (ported from shader 1) ----
		// These run as a post-process on top of the palette result above.
		// `uv` is already the pixelated coordinate from the top of the
		// function, so every effect below inherits that grid automatically.

		float roll_time = roll ? TIME : 0.0;
		float roll_line = 0.0;
		vec2 roll_uv = vec2(0.0);
		if (roll || noise_opacity > 0.0) {
			roll_line = smoothstep(0.3, 0.9, sin(uv.y * roll_size - (roll_time * roll_speed)));
			roll_line *= roll_line * smoothstep(0.3, 0.9, sin(uv.y * roll_size * roll_variation - (roll_time * roll_speed * roll_variation)));
			roll_uv = vec2((roll_line * distort_intensity * (1.0 - uv.x)), 0.0);
		}

		// Chromatic aberration / roll-distorted resample of the screen
		vec3 crt_color;
		if (roll) {
			crt_color.r = texture(SCREEN_TEXTURE, uv + roll_uv * 0.8 + vec2(aberration, 0.0) * 0.1).r;
			crt_color.g = texture(SCREEN_TEXTURE, uv + roll_uv * 1.2 - vec2(aberration, 0.0) * 0.1).g;
			crt_color.b = texture(SCREEN_TEXTURE, uv + roll_uv).b;
		} else {
			crt_color.r = texture(SCREEN_TEXTURE, uv + vec2(aberration, 0.0) * 0.1).r;
			crt_color.g = texture(SCREEN_TEXTURE, uv - vec2(aberration, 0.0) * 0.1).g;
			crt_color.b = texture(SCREEN_TEXTURE, uv).b;
		}

		// This mix amount only controls how much of the aberration/roll resample
		// shows through -- pixelation above is always fully (100%) applied and
		// is independent of this value.
		float crt_mix = clamp(abs(aberration) * 5.0 + roll_line * float(roll), 0.0, 1.0);
		final_color.rgb = mix(final_color.rgb, crt_color, crt_mix);

		if (noise_opacity > 0.0) {
			float n = smoothstep(0.4, 0.5, noise(uv * vec2(2.0, 200.0) + vec2(10.0, TIME * noise_speed)));
			float grain = roll_line * n * clamp(random(uv + vec2(TIME * 0.8, 0.0)).x + 0.8, 0.0, 1.0);
			final_color.rgb = clamp(mix(final_color.rgb, final_color.rgb + grain, noise_opacity), vec3(0.0), vec3(1.0));
		}

		if (static_noise_intensity > 0.0) {
			final_color.rgb += clamp(random(uv + fract(TIME)).x, 0.0, 1.0) * static_noise_intensity;
		}

		if (discolor) {
			float saturation = 0.5;
			float contrast = 1.2;
			vec3 greyscale = vec3(final_color.r + final_color.g + final_color.b) / 3.0;
			final_color.rgb = mix(final_color.rgb, greyscale, saturation);

			float midpoint = pow(0.5, 2.2);
			final_color.rgb = (final_color.rgb - vec3(midpoint)) * contrast + midpoint;
		}

		if (dither_strength > 0.0) {
			float psx_dither = hash(uv * 80.0 + floor(TIME * 50.0));
			final_color.rgb += (psx_dither - 0.5) * dither_strength;
		}

		float levels = pow(2.0, float(color_bit_depth));
		final_color.rgb = floor(clamp(final_color.rgb, 0.0, 1.0) * levels) / levels;
	}
	COLOR = final_color;
}
