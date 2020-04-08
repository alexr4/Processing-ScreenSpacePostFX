//non linearized depth
#version 150
#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;
uniform sampler2D depthmap;
uniform sampler2D bluenoise;
uniform sampler2D blurred;
uniform vec2 mouse;
uniform vec2 resolution;
uniform vec3 dir;
uniform float near = 100.0;
uniform float far = 400.0;


in vec4 vertTexCoord;
out vec4 fragColor;

#include ../data/gaussianblur13x13.glsl

float ldepth(in float d){
	float nd = (2.0 * near) / (far + near - d * (far - near));
	return nd;
}


void main(){
	vec2 uv = vertTexCoord.xy;
    vec3 rgb = texture2D(texture, uv).rgb;
    vec3 blur = texture2D(blurred, uv).rgb;

    float depth = texture2D(depthmap, uv).r;
    float ld = ldepth(depth);

    float fogDistance = smoothstep(0.25, 0.5, ld);
    float fogAmount = 1.0 - exp( -fogDistance*1.0);

    vec3  fogColor  = vec3(0.7098, 0.7765, 0.8471);
    vec3 fogrgb = mix(blur, fogColor, fogAmount );
    vec3 frgb =  mix(rgb, fogrgb, fogDistance);

    vec3 brgb = getBlur(uv, texture, 25.0 * fogDistance, 1.0 / dir.z, dir.xy);
    float bdepth = getBlur(uv, depthmap, 25.0 * fogDistance, 1.0 / dir.z, dir.xy).r;
    brgb      = fogDistance > 0.0 ? brgb : rgb;
    bdepth      = fogDistance > 0.0 ? bdepth : depth;

	fragColor = vec4(brgb, bdepth);
}