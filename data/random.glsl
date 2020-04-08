#define RANDOM_SEED 43758.5453123

float random(float x){
    return fract(sin(x) * RANDOM_SEED);
}

float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))* RANDOM_SEED);
}

vec3 random3(vec3 c) {
	float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}