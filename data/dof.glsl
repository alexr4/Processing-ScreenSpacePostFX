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

const float GOLDEN_ANGLE = 2.39996323; 
const float MAX_BLUR_SIZE = 25.0; 
const float RAD_SCALE = 0.5; // Smaller = nicer blur, larger = faster

in vec4 vertTexCoord;
out vec4 fragColor;

float ldepth(in float d){
	float nd = (2.0 * near) / (far + near - d * (far - near));
	return nd;
}

float getBlurSize(float depth, float focusPoint, float focusScale)
{
	float coc = clamp((1.0 / focusPoint - 1.0 / depth)*focusScale, -1.0, 1.0);
	return abs(coc) * MAX_BLUR_SIZE;
}

vec3 depthOfField(vec2 texCoord, float focusPoint, float focusScale)
{
	vec2 pixelSize = vec2(1.0) / resolution;

	float centerDepth = ldepth(texture2D(depthmap, texCoord).r) * far;
	float centerSize = getBlurSize(centerDepth, focusPoint, focusScale);
	vec3 color = texture2D(texture, texCoord).rgb;
	float tot = 1.0;
	float radius = RAD_SCALE;
	for (float ang = 0.0; radius<MAX_BLUR_SIZE; ang += GOLDEN_ANGLE)
	{
		vec2 tc = texCoord + vec2(cos(ang), sin(ang)) * pixelSize * radius;
		vec3 sampleColor = texture2D(texture, tc).rgb;
		float sampleDepth = ldepth(texture2D(depthmap, tc).r) * far;
		float sampleSize = getBlurSize(sampleDepth, focusPoint, focusScale);
		if (sampleDepth > centerDepth)
			sampleSize = clamp(sampleSize, 0.0, centerSize*2.0);
		float m = smoothstep(radius-0.5, radius+0.5, sampleSize);
		color += mix(color/tot, sampleColor, m);
		tot += 1.0;   
		radius += RAD_SCALE/radius;
	}
	return color /= tot;
}
void main(){
	vec2 uv = vertTexCoord.xy;
	vec3 rgb = depthOfField(uv, focusPoint, scale);

	fragColor = vec4(rgb, 1.0);
}