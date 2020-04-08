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
uniform vec2 resolution;
uniform float focusPoint = 50.0;
uniform float scale = 50.0;
uniform float near = 10.0;
uniform float far = 400;
/*
const float GOLDEN_ANGLE = 2.39996323; 
const float MAX_BLUR_SIZE = 25.0; 
const float RAD_SCALE = 0.5; // Smaller = nicer blur, larger = faster
*/
in vec4 vertTexCoord;
out vec4 fragColor;

float ldepth(in float d){
	float nd = (2.0 * near) / (far + near - d * (far - near));
	return nd;
}

float getBlurSize(float depth, float focusPoint, float focusScale)
{
	float coc = clamp((1.0 / focusPoint - 1.0 / depth)*focusScale, -1.0, 1.0);
	return abs(coc);//abs(coc) * MAX_BLUR_SIZE;
}

vec3 depthOfField(vec2 texCoord, float focusPoint, float focusScale)
{
	vec2 pixelSize = vec2(1.0) / resolution;

	float centerDepth = ldepth(texture2D(depthmap, texCoord).r) * far;
	float centerSize = getBlurSize(centerDepth, focusPoint, focusScale);
    float asum = 0.0;
    vec3 col = vec3(0.0);
    for(float t = 0.0; t < 8.0 * 2.0 * 3.14; t += 3.14 / 32.0) {
    	float r = cos(3.14 / 6.0) / cos(mod(t, 2.0 * 3.14 / 6.0) - 3.14 / 6.0);
        
        // Tap filter once for coc
        vec2 offset = vec2(sin(t), cos(t)) * r * t * pixelSize * centerSize;
        vec4 samp = texture2D(texture, texCoord + offset * 1.0);
	    float sampDepth = ldepth(texture2D(depthmap, texCoord + offset * 1.0).r) * far;
	    float sampSize = getBlurSize(sampDepth, focusPoint, focusScale);
        
        // Tap filter with coc from texture
        offset = vec2(sin(t), cos(t)) * r * t * pixelSize * sampSize;
        samp = texture2D(texture, texCoord + offset * 1.0);
	    sampDepth = ldepth(texture2D(depthmap, texCoord + offset * 1.0).r) * far;
	    sampSize = getBlurSize(sampDepth, focusPoint, focusScale);
        
        // weigh and save
        col += samp.rgb *sampSize * t;
        asum += sampSize * t;
    }
    col = col / asum;
    return col;
}
void main(){
	vec2 uv = vertTexCoord.xy;
	vec3 rgb = depthOfField(uv, focusPoint, scale);

	fragColor = vec4(rgb, 1.0);
}