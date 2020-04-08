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

in vec4 vertTexCoord;
out vec4 fragColor;

float ldepth(in float d){
	float nd = (2.0 * near) / (far + near - d * (far - near));
	return nd;
}

float getBlurSize(float depth, in float focusPoint, in float focusScale)
{
    float coc = (focusScale/(far-near)) * abs(1.0 - (focusPoint/(far-near)) / (depth/(far-near)));
	return max(0.01, min(0.35, coc));
}


vec3 hexablur(vec2 uv, float focusPoint, float focusScale) {
    vec2 scale = vec2(1.0) / resolution.xy;
    vec3 col = vec3(0.0);
    float asum = 0.0;
    
	float centerDepth = ldepth(texture2D(depthmap, uv).r) * far;
	float coc = getBlurSize(centerDepth, focusPoint, focusScale);

    for(float t = 0.0; t < 8.0 * 2.0 * 3.14; t += 3.14 / 32.0) {
    	float r = cos(3.14 / 6.0) / cos(mod(t, 2.0 * 3.14 / 6.0) - 3.14 / 6.0);
        
        // Tap filter once for coc
        vec2 offset = vec2(sin(t), cos(t)) * r * t * scale * coc;
        vec4 samp = texture2D(texture, uv + offset * 1.0);
	    float sampDepth = ldepth(texture2D(depthmap, uv + offset * 1.0).r) * far;
	    float scoc = getBlurSize(sampDepth, focusPoint, focusScale);
        
        // Tap filter with coc from texture
        offset = vec2(sin(t), cos(t)) * r * t * scale * scoc;
        samp = texture2D(texture, uv + offset * 1.0);
	    sampDepth = ldepth(texture2D(depthmap, uv + offset * 1.0).r) * far;
	    scoc = getBlurSize(sampDepth, focusPoint, focusScale);
        
        // weigh and save
        col += samp.rgb * scoc * t;
        asum += scoc * t;
        
    }
    col = col / asum;
    return col;
}

void main(){
	vec2 uv = vertTexCoord.xy;
    vec3 rgb = hexablur(uv, focusPoint, scale);

	fragColor = vec4(rgb, 1.0);
}
