//non linearized depth
#version 150
#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform mat4 InvVP;
uniform sampler2D texture;
uniform sampler2D depthmap;
uniform sampler2D bluenoise;
uniform vec2 resolution;
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

#include ../data/random.glsl

vec3 reconstructPosition(vec2 uv, float z, mat4 InvVP)
{
    float x = uv.x * 2.0f - 1.0f;
    float y = (1.0 - uv.y) * 2.0f - 1.0f;
    vec4 position_s = vec4(x, y, z, 1.0f);
    vec4 position_v = InvVP * position_s;
    vec3 P = position_v.xyz / position_v.w;

    return P.xyz;
}

vec3 getNormal(vec2 uv, sampler2D depthmap, mat4 InvVP){
    vec2 texel = (vec2(1.0) / resolution) * 0.5;

    vec2 center         = uv + texel;
    vec2 up             = uv + texel + vec2(0.0, 1.0) * texel;
    vec2 down           = uv + texel + vec2(0.0, -1.0) * texel;
    vec2 left           = uv + texel + vec2(-1.0, 0.0) * texel;
    vec2 right          = uv + texel + vec2(1.0, 0.0) * texel;

    float depth         = texture2D(depthmap, center).r;
    float depthup       = texture2D(depthmap, up).r;
    float depthdown     = texture2D(depthmap, down).r;
    float depthleft     = texture2D(depthmap, left).r;
    float depthright    = texture2D(depthmap, right).r;

    float diffCU        =  abs(depth - depthup);
    float diffCD        =  abs(depth - depthdown);
    float diffCL        =  abs(depth - depthleft);
    float diffCR        =  abs(depth - depthright);


	vec3 P0 = reconstructPosition(center,  depth, InvVP);
	vec3 P1 = reconstructPosition(up, depthup, InvVP);
	vec3 P2 = reconstructPosition(left, depthleft, InvVP);
	vec3 P3 = reconstructPosition(down, depthdown, InvVP);
	vec3 P4 = reconstructPosition(right, depthright, InvVP);

    vec3 V;
    vec3 H;
    if(diffCU < diffCD){
        V = P1;
    }else{
        V = P3;
    }
    if(diffCL < diffCR){
        H = P2;
    }else{
        H = P4;
    }
	vec3 normal = cross(H-P0, V-P0);
	normal.z *= -1.0;

	return normalize(normal);
}



float getSSAO(vec2 uv, sampler2D depthmap){
    float strength = 1.0;
    float base = 0.05;

    float area = 0.15;
    float falloff = 0.0125;

    float radius = 0.025;

    // vec3 rnd = random3(vec3(100 + uv, uv.x + 514256.0)); //try blue noise
    vec3 rnd = normalize(texture2D(bluenoise, fract(uv * 4.0)).rgb);

    float depth = texture2D(depthmap, uv).r;

    vec3 position = vec3(uv, depth);
    vec3 normal = getNormal(uv, depthmap, InvVP);

    float radiusDepth = radius / depth;
    float occ = 0.0;
    for(int i=0; i<samples; i++){
        vec3 ray = radiusDepth * reflect(sampleSphere[i], rnd);
        vec3 hemiRay = position + sign(dot(ray, normal)) * ray;

        float occDepth = texture2D(depthmap, clamp(hemiRay.xy, vec2(0.0), vec2(1.0))).r;
        float diff = (depth - occDepth);

        occ += (1.0 - smoothstep(falloff, area, diff)) *  step(falloff, diff);
    }

    float ao = 1.0 - (strength * occ) / samples;

  return clamp(ao + base, 0.0, 1.0) * (1.0 - step(1.0, depth)) + step(1.0, depth);
}

void main(){
	vec2 uv = vertTexCoord.xy;
    vec4 albedo = texture2D(texture, uv);
	float ao = getSSAO(uv, depthmap);

    vec3 color = vec3(ao);
	fragColor = vec4(color, 1.0);
}