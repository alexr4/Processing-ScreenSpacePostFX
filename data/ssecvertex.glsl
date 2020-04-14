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
uniform vec2 resolution;


in vec4 vertTexCoord;
out vec4 fragColor;


float ldepth(in float d){
	float nd = (2.0 * near) / (far + near - d * (far - near));
	return nd;
}

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

    float depth = (texture2D(depthmap, uv).r);
    vec3 ecVertex = reconstructPosition(depth, vertTexCoord.xy * 2.0 - 1.0, projmat);

    float stepper = 1.0 - step(1.0, depth);
	fragColor = vec4(ecVertex, stepper);
}