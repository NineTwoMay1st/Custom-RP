#ifndef CUSTOM_BRDF_INCLUDED
#define CUSTOM_BRDF_INCLUDED

struct BRDF {
	float3 diffuse;
	float3 specular;
	float roughness;
};

#define MIN_REFLECTIVITY 0.04

//The reflectivity of nonmetals varies, but is about 0.04 on average.this function that adjusts the OneMinusReflectivity range from 0–1 to 0–0.96
float OneMinusReflectivity (float metallic) {
	float range = 1.0 - MIN_REFLECTIVITY;
	return range - metallic * range;
}

BRDF GetBRDF (Surface surface, bool applyAlphaToDiffuse = false) {
	BRDF brdf;
	float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);

	brdf.diffuse = surface.color * oneMinusReflectivity;   //金属漫反射较少
	if (applyAlphaToDiffuse) {   // 		当为true时，主要为了半透明的物体，即漫反射部分穿过，高光不穿过。当为false时，为透明物体使用，此时高光和漫反射都为部分穿过，剩余反射。
		brdf.diffuse *= surface.alpha;
	}
	brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);

	//likely   Roughness is the opposite of smoothness, so we can simply take one minus smoothness.
	float perceptualRoughness =
		PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
	brdf.roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
	return brdf;
}

float SpecularStrength (Surface surface, BRDF brdf, Light light) {
	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float nh2 = Square(saturate(dot(surface.normal, h)));
	float lh2 = Square(saturate(dot(light.direction, h)));
	float r2 = Square(brdf.roughness);
	float d2 = Square(nh2 * (r2 - 1.0) + 1.00001);
	float normalization = brdf.roughness * 4.0 + 2.0;
	return r2 / (d2 * max(0.1, lh2) * normalization);
}

float3 DirectBRDF (Surface surface, BRDF brdf, Light light) {
	return SpecularStrength(surface, brdf, light) * brdf.specular + brdf.diffuse;
}

#endif