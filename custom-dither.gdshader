shader_type canvas_item;


// ---------------------------------------------------------------------------
// OKLab palette dithering
//
// Approximation of the "dither towards the enclosing simplex" idea:
// instead of a true tetrahedralization / natural-neighbor search, we take the
// 4 nearest palette entries in (ab-squeezed) OKLab space, weight them with a
// Gaussian falloff on distance, and stochastically pick ONE of the four per
// pixel using a blue-noise (or Bayer) threshold. This is exactly the
// simplification the original author landed on, and it's far cheaper on a
// GPU than real Delaunay/tetrahedral search.
//
// "Fake" palette entries: palette_lab[i] is the point used for searching/
// weighting, palette_rgb[i] is what actually gets drawn. They don't have to
// match — a fake entry can sit at a useful spot in color space purely to
// shape the dither pattern, while outputting a real palette color.
// ---------------------------------------------------------------------------

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

uniform float ab_scale : hint_range(0.0, 1.5) = 0.7;      // squeeze OKLab a/b before measuring distance
uniform float sigma : hint_range(0.001, 0.5) = 0.06;      // Gaussian bandwidth for weighting
uniform float jitter_strength : hint_range(0.0, 0.1) = 0.0; // tiny random OKLab offset pre-search

uniform int palette_count = 8;
uniform vec3 palette_lab[64]; // search-space OKLab (L, a, b), unscaled
uniform vec3 palette_rgb[64]; // actual output color (sRGB 0..1) for that index

uniform bool use_blue_noise = true;
uniform sampler2D blue_noise_tex; // R channel, ideally a real blue-noise tile
uniform vec2 noise_tex_size = vec2(64.0, 64.0);

// --- sRGB <-> linear -------------------------------------------------------

float srgb_to_linear1(float c) {
	return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}
vec3 srgb_to_linear(vec3 c) {
	return vec3(srgb_to_linear1(c.r), srgb_to_linear1(c.g), srgb_to_linear1(c.b));
}

// --- linear sRGB <-> OKLab (Björn Ottosson's formulas) ----------------------

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

vec3 rgb_to_oklab(vec3 srgb) {
	return linear_to_oklab(srgb_to_linear(srgb));
}

// --- cheap per-pixel hash for jitter ----------------------------------------

float hash1(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// --- fallback 8x8 Bayer matrix (used if use_blue_noise == false) -----------

const float BAYER8x8[64] = float[64](
	0.0, 32.0, 8.0, 40.0, 2.0, 34.0, 10.0, 42.0,
	48.0, 16.0, 56.0, 24.0, 50.0, 18.0, 58.0, 26.0,
	12.0, 44.0, 4.0, 36.0, 14.0, 46.0, 6.0, 38.0,
	60.0, 28.0, 52.0, 20.0, 62.0, 30.0, 54.0, 22.0,
	3.0, 35.0, 11.0, 43.0, 1.0, 33.0, 9.0, 41.0,
	51.0, 19.0, 59.0, 27.0, 49.0, 17.0, 57.0, 25.0,
	15.0, 47.0, 7.0, 39.0, 13.0, 45.0, 5.0, 37.0,
	63.0, 31.0, 55.0, 23.0, 61.0, 29.0, 53.0, 21.0
);

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	vec3 target = rgb_to_oklab(src.rgb);

	// optional tiny jitter in OKLab space, breaks up residual banding
	if (jitter_strength > 0.0) {
		vec3 j = vec3(
			hash1(FRAGCOORD.xy + vec2(0.0, 0.0)),
			hash1(FRAGCOORD.xy + vec2(13.1, 7.7)),
			hash1(FRAGCOORD.xy + vec2(91.7, 3.3))
		) - 0.5;
		target += j * jitter_strength;
	}

	// find the 4 nearest palette entries (ab-squeezed distance), sorted
	int idx[4] = int[4](-1, -1, -1, -1);
	float dist[4] = float[4](1e20, 1e20, 1e20, 1e20);

	for (int i = 0; i < palette_count; i++) {
		vec3 diff = target - palette_lab[i];
		diff.yz *= ab_scale;
		float d = dot(diff, diff);

		if (d < dist[3]) {
			int j = 3;
			while (j > 0 && dist[j - 1] > d) {
				dist[j] = dist[j - 1];
				idx[j] = idx[j - 1];
				j -= 1;
			}
			dist[j] = d;
			idx[j] = i;
		}
	}

	// Gaussian weights from distance, normalized
	float w[4];
	float wsum = 0.0;
	for (int i = 0; i < 4; i++) {
		if (idx[i] >= 0) {
			w[i] = exp(-dist[i] / (2.0 * sigma * sigma));
		} else {
			w[i] = 0.0;
		}
		wsum += w[i];
	}
	if (wsum > 0.0) {
		for (int i = 0; i < 4; i++) {
			w[i] /= wsum;
		}
	}

	// dithering threshold
	float r;
	if (use_blue_noise) {
		r = texture(blue_noise_tex, FRAGCOORD.xy / noise_tex_size).r;
	} else {
		ivec2 p = ivec2(mod(FRAGCOORD.xy, 8.0));
		r = (BAYER8x8[p.y * 8 + p.x] + 0.5) / 64.0;
	}

	// weighted stochastic pick among the 4 candidates
	vec3 out_rgb = src.rgb;
	float cum = 0.0;
	for (int i = 0; i < 4; i++) {
		if (idx[i] < 0) {
			continue;
		}
		cum += w[i];
		if (r < cum) {
			out_rgb = palette_rgb[idx[i]];
			break;
		}
	}

	COLOR = vec4(out_rgb, src.a);
}
