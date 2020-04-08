//non linearized depth
#version 150
#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform mat4 projmat;
uniform mat4 mv;
uniform sampler2D texture;
uniform sampler2D depthmap;
uniform vec3 fogColor = vec3(0.9137, 0.9608, 0.9882);
uniform vec3 sunColor = vec3(1.0, 0.9, 0.7);// yellowish
uniform float fogDensity = 0.0005;
uniform float near = 10.0;
uniform float far = 400.0;
uniform vec3 sunDir;
uniform vec2 mouse;


in vec4 vertTexCoord;
out vec4 fragColor;


float ldepth(in float d){
	float nd = (2.0 * near) / (far + near - d * (far - near));
	return nd;
}

vec3 reconstructPosition(in float z, in vec2 uv, mat4 projmat, mat4 mv)
{
    float x = uv.x * 2.0f - 1.0f;
    float y = (1.0 - uv.y) * 2.0f - 1.0f;
    vec4 position_s = vec4(x, y, z, 1.0f);
    vec4 position_v = projmat * position_s;
    vec4 P = position_v / position_v.w;
    vec4 worldPosition = mv * P;

    return position_v.xyz;
}



void main(){
	vec2 uv = vertTexCoord.xy;
    vec4 albedo = texture2D(texture, uv);

    float depth = texture2D(depthmap, uv).r * far;
    vec3 ecVertex = reconstructPosition(depth, uv, (projmat), mv);

    float dist = length(ecVertex);
    float fogFactor;
    float sunAmount = max(dot(-ecVertex.xyz / far, sunDir), 0.0);
    vec3 scatteringSun = mix(fogColor, sunColor, pow(sunAmount, 10.0));
    vec3 finalColor;

    if(FOGTYPE == 0){ //linear
        fogFactor = (far - dist) / (far - near);
        fogFactor = clamp(fogFactor, 0.0, 1.0);

        finalColor = mix(scatteringSun, albedo.rgb, fogFactor);
    }else if(FOGTYPE == 1){//exponential
        fogFactor = exp(-dist * fogDensity);
        fogFactor = clamp(fogFactor, 0.0, 1.0);

        finalColor = mix(scatteringSun, albedo.rgb, fogFactor);
    }else if(FOGTYPE == 2){
        float be = 0.0025; //extinction
        float bi = 0.002; //inscattring
        float ext = exp(-dist * be);
        float insc = exp(-dist * bi);
        finalColor = albedo.rgb * (ext) + scatteringSun * (1.0 - insc);
    }

	fragColor = vec4(finalColor, 1.0);
}