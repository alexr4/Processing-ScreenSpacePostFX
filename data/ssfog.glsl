//non linearized depth
#version 150
#ifdef GL_ES
precision highp float;
precision highp int;
#endif

uniform mat4 projmat;
uniform sampler2D texture;
uniform sampler2D depthmap;
uniform sampler2D ramp;
uniform vec3 fogColor = vec3(0.9137, 0.9608, 0.9882);
uniform vec3 sunColor = vec3(1.0, 0.9, 0.7);// yellowish
uniform float fogDensity = 0.0005;
uniform float near = 10.0;
uniform float far = 400.0;
uniform vec3 sunDir;
uniform vec2 mouse;

in vec4 vertTexCoord;
out vec4 fragColor;


vec3 reconstructPosition(in float z, in vec2 uv, mat4 projmat)
{
//from https://stackoverflow.com/questions/11277501/how-to-recover-view-space-position-given-view-space-depth-value-and-ndc-xy
    mat4 inversePrjMat = inverse(projmat);
    vec4 viewPosH      = inversePrjMat * vec4(uv.x, uv.y,  z * 2.0 - 1.0, 1.0 );
    vec3 viewPos       = viewPosH.xyz / viewPosH.w;

    return viewPos;
}


void main(){
	vec2 uv = vertTexCoord.xy;
    vec4 albedo = texture2D(texture, uv);

    float depth = texture2D(depthmap, uv).r;
    vec3 ecVertex = reconstructPosition(depth, vertTexCoord.xy * 2.0 - 1.0, projmat);

    float dist = length(ecVertex);
    float fogFactor;
    float sunAmount = max(dot(normalize(ecVertex.xyz), sunDir), 0.0);
    //use this if you want to use a ramp instead of colors
    //vec3 scatteringSun = texture2D(ramp, vec2(pow(sunAmount, 25.0), 0.5)).rgb;
    vec3 scatteringSun = mix(fogColor, sunColor, pow(sunAmount, 15.0));

    vec3 finalColor;

    if(FOGTYPE == 0){ //linear
        fogFactor = (far - dist) / (far - near);
        fogFactor = 1.0 - clamp(fogFactor, 0.0, 1.0);

        finalColor = mix(albedo.rgb, scatteringSun, fogFactor);
    }else if(FOGTYPE == 1){//exponential
        fogFactor = exp(-dist * fogDensity);
        fogFactor = clamp(fogFactor, 0.0, 1.0);

        finalColor = mix(albedo.rgb, scatteringSun, 1.0 - fogFactor);
    }else if(FOGTYPE == 2){
        float be = 0.0025; //extinction
        float bi = 0.002; //inscattring
        float ext = exp(-dist * be);
        float insc = exp(-dist * bi);
        finalColor = albedo.rgb * ext + scatteringSun * (1.0 - insc);
    }


	fragColor = vec4(finalColor, 1.0);
}