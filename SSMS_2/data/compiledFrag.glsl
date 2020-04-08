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

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PI 3.1415926535897932384626433832795
#define avgPos(i) 	avgValue += texture2D(tex, uv - i * blurSize * dir) * incrementalGaussian.x;
#define avgNeg(i) 	avgValue += texture2D(tex, uv + i * blurSize * dir) * incrementalGaussian.x; 
#define coeff()	  	coefficientSum += 2.0 * incrementalGaussian.x;
#define incGauss()	incrementalGaussian.xy *= incrementalGaussian.yz;
#define blur(i)		avgPos(i); avgNeg(i); coeff(); incGauss();
#define blur5x5()	blur(1); blur(2);
#define blur7x7()	blur5x5(); blur(3);
#define blur9x9()	blur7x7(); blur(4);
#define blur13x13()	blur9x9(); blur(5); blur(6); blur(7);

vec3 getBlur(vec2 uv, sampler2D tex, float sigma, float blurSize,  vec2 dir){
	
	// Incremental Gaussian Coefficent Calculation (See GPU Gems 3 pp. 877 - 889)

	vec3 incrementalGaussian;
	incrementalGaussian.x = 1.0 / (sqrt(2.0 * PI) * sigma);
	incrementalGaussian.y = exp(-0.5 / (sigma * sigma));
	incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;

 	vec4 avgValue = vec4(0.0, 0.0, 0.0, 0.0);
 	float coefficientSum = 0.0;

  	// Take the central sample first...
  	avgValue += texture2D(tex, uv) * incrementalGaussian.x;
  	coefficientSum += incrementalGaussian.x;
  	incrementalGaussian.xy *= incrementalGaussian.yz;

  	blur13x13();

  	return (avgValue / coefficientSum).rgb;
}

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
