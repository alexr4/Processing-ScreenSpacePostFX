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