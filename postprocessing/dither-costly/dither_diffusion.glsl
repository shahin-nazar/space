#[compute]
#version 450

// Serial (single-invocation) Floyd-Steinberg error diffusion, quantizing
// against an OKLab palette. One GPU thread walks the entire image in raster
// order — this is required for correctness (error diffusion is inherently
// sequential), so keep the source resolution low (pixel-art scale).

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform sampler2D src_tex;
layout(rgba8, set = 0, binding = 1) uniform writeonly image2D out_img;

layout(set = 0, binding = 2, std430) restrict readonly buffer PaletteLab {
	vec4 palette_lab[]; // xyz = OKLab search point, w unused
};
layout(set = 0, binding = 3, std430) restrict readonly buffer PaletteRgb {
	vec4 palette_rgb[]; // xyz = actual output sRGB, w unused
};

// carries diffused error between not-yet-processed pixels; cleared to 0
// every frame from GDScript before dispatch
layout(rgba32f, set = 0, binding = 4) uniform image2D error_img;

layout(push_constant, std430) uniform Params {
	int width;
	int height;
	int palette_count;
	float ab_scale;
} params;

float srgb_to_linear1(float c) {
	return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}
vec3 srgb_to_linear(vec3 c) {
	return vec3(srgb_to_linear1(c.r), srgb_to_linear1(c.g), srgb_to_linear1(c.b));
}
vec3 linear_to_oklab(vec3 c) {
	float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
	float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
	float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;
	float l_ = pow(max(l, 0.0), 1.0 / 3.0);
	float m_ = pow(max(m, 0.0), 1.0 / 3.0);
	float s_ = pow(max(s, 0.0), 1.0 / 3.0);
	return vec3(
		0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
		1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
		0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
	);
}
vec3 rgb_to_oklab(vec3 c) { return linear_to_oklab(srgb_to_linear(c)); }

void main() {
	int w = params.width;
	int h = params.height;

	for (int y = 0; y < h; y++) {
		for (int x = 0; x < w; x++) {
			ivec2 p = ivec2(x, y);
			vec4 src = texelFetch(src_tex, p, 0);
			vec3 lab = rgb_to_oklab(src.rgb);

			vec4 carried = imageLoad(error_img, p);
			lab += carried.rgb;

			// nearest single palette entry (ab-squeezed distance)
			float best_d = 1e20;
			int best_i = 0;
			for (int i = 0; i < params.palette_count; i++) {
				vec3 diff = lab - palette_lab[i].xyz;
				diff.yz *= params.ab_scale;
				float d = dot(diff, diff);
				if (d < best_d) {
					best_d = d;
					best_i = i;
				}
			}

	vec3 chosen_rgb = palette_rgb[best_i].xyz;
	vec3 chosen_lab = rgb_to_oklab(chosen_rgb);

	vec3 err = lab - chosen_lab;
	err = clamp(err, vec3(-0.16), vec3(0.16));	
	// err *= 0.7;
	err.x *= 0.8;
	err.yz *= 0.6;

	if (x + 1 < w) {
		vec4 e = imageLoad(error_img, ivec2(x + 1, y));
		imageStore(error_img, ivec2(x + 1, y), e + vec4(err * (7.0 / 16.0), 0.0));
	}
	if (y + 1 < h) {
		if (x - 1 >= 0) {
			vec4 e = imageLoad(error_img, ivec2(x - 1, y + 1));
			imageStore(error_img, ivec2(x - 1, y + 1), e + vec4(err * (3.0 / 16.0), 0.0));
		}
		vec4 e2 = imageLoad(error_img, ivec2(x, y + 1));
		imageStore(error_img, ivec2(x, y + 1), e2 + vec4(err * (5.0 / 16.0), 0.0));
		if (x + 1 < w) {
			vec4 e3 = imageLoad(error_img, ivec2(x + 1, y + 1));
			imageStore(error_img, ivec2(x + 1, y + 1), e3 + vec4(err * (1.0 / 16.0), 0.0));
		}
	}

	vec3 final_rgb = mix(src.rgb, chosen_rgb, 0.7); // 0 = original game colors, 1 = full dither
	imageStore(out_img, p, vec4(final_rgb, src.a));


			
		}
	}
}
