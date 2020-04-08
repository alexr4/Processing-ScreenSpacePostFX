//non linearized depth
#version 150
#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;
uniform sampler2D depthmap;
uniform sampler2D bluenoise;
uniform vec2 mouse;
uniform float near;
uniform float far;

#define samples 16
const vec3 sampleSphere[samples] = vec3[] (
    vec3( 0.5381, 0.1856,-0.4319), vec3( 0.1379, 0.2486, 0.4430),
    vec3( 0.3371, 0.5679,-0.0057), vec3(-0.6999,-0.0451,-0.0019),
    vec3( 0.0689,-0.1598,-0.8547), vec3( 0.0560, 0.0069,-0.1843),
    vec3(-0.0146, 0.1402, 0.0762), vec3( 0.0100,-0.1924,-0.0344),
    vec3(-0.3577,-0.5301,-0.4358), vec3(-0.3169, 0.1063, 0.0158),
    vec3( 0.0103,-0.5869, 0.0046), vec3(-0.0897,-0.4940, 0.3287),
    vec3( 0.7119,-0.0154,-0.0918), vec3(-0.0533, 0.0596,-0.5411),
    vec3( 0.0352,-0.0631, 0.5460), vec3(-0.4776, 0.2847,-0.0271)
);

in vec4 vertTexCoord;
out vec4 fragColor;

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


vec3 getNormal(float depth, vec2 uv, sampler2D depthmap){

	vec2 offsety = vec2(0.0, 0.0001);
	vec2 offsetx = vec2(0.0001, 0.0);

	float depthoy = texture2D(depthmap, uv + offsety).r;
	float depthox = texture2D(depthmap, uv + offsetx).r;

	vec3 py = vec3(offsety, depthoy - depth);
	vec3 px = vec3(offsetx, depthox - depth);

	vec3 normal = cross(py, px);
	normal.z *= -1.0;

	return normalize(normal);
}

float getSSAO(vec2 uv, sampler2D depthmap){
    float strength = 1.0;
    float base = 0.05;

    float area = 0.15;
    float falloff = 0.0115;

    float radius = 0.025;

    // vec3 rnd = random3(vec3(100 + uv * 100.0, uv.x + 514256.0)); //try blue noise
    vec3 rnd = normalize(texture2D(bluenoise, fract(uv * 4.0)).rgb);

    float depth = texture2D(depthmap, uv).r;

    vec3 position = vec3(uv, depth);
    vec3 normal = getNormal(depth, uv, depthmap);

    float radiusDepth = radius / depth;
    float occ = 0.0;

    for(int i=0; i<samples; i++){
        vec3 ray = radiusDepth * reflect(sampleSphere[i], rnd);
        vec3 hemiRay = position + sign(dot(ray, normal)) * ray;

        float occDepth = texture2D(depthmap, clamp(hemiRay.xy, vec2(0.0), vec2(1.0))).r;
        float diff = (depth - occDepth);


        occ +=  step(falloff, diff) * (1.0 - smoothstep(falloff, area, diff));
        // float rangeCheck = smoothstep(0.0, 1.0, radius / abs(diff));
        // occ       += (occDepth >= depth + mouse.x ? 1.0 : 0.0) * rangeCheck;    
    }
    
    
    float ao = 1.0 - strength * occ * (1.0 / samples);
    return clamp(ao + base, 0.0, 1.0) * (1.0 - step(1.0, depth)) + step(1.0, depth);
}

void main(){
	vec2 uv = vertTexCoord.xy;
	float ao = getSSAO(uv, depthmap);

    vec3 color = vec3(ao);
	fragColor = vec4(color, 1.0);
}
