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

void getBlur(in vec2 uv, in sampler2D tex, in float sigma,
             out vec3 incrementalGaussian, out vec4 avgValue, out float coefficientSum){
	
	// Incremental Gaussian Coefficent Calculation (See GPU Gems 3 pp. 877 - 889)

	incrementalGaussian;
	incrementalGaussian.x = 1.0 / (sqrt(2.0 * PI) * sigma);
	incrementalGaussian.y = exp(-0.5 / (sigma * sigma));
	incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;

 	avgValue = vec4(0.0, 0.0, 0.0, 0.0);
 	coefficientSum = 0.0;

  	// Take the central sample first...
  	avgValue += texture2D(tex, uv) * incrementalGaussian.x;
  	coefficientSum += incrementalGaussian.x;
  	incrementalGaussian.xy *= incrementalGaussian.yz;

}

vec3 getBlur13x13(vec2 uv, sampler2D tex, float sigma, float blurSize,  vec2 dir){

	vec3 incrementalGaussian;
 	vec4 avgValue;
 	float coefficientSum;

    getBlur(uv, tex, sigma, incrementalGaussian, avgValue, coefficientSum);
  	blur13x13();

  	return (avgValue / coefficientSum).rgb;
}

vec3 getBlur9x9(vec2 uv, sampler2D tex, float sigma, float blurSize,  vec2 dir){

	vec3 incrementalGaussian;
 	vec4 avgValue;
 	float coefficientSum;

    getBlur(uv, tex, sigma, incrementalGaussian, avgValue, coefficientSum);
  	blur9x9();

  	return (avgValue / coefficientSum).rgb;
}

vec3 getBlur7x7(vec2 uv, sampler2D tex, float sigma, float blurSize,  vec2 dir){

	vec3 incrementalGaussian;
 	vec4 avgValue;
 	float coefficientSum;

    getBlur(uv, tex, sigma, incrementalGaussian, avgValue, coefficientSum);
  	blur7x7();

  	return (avgValue / coefficientSum).rgb;
}

vec3 getBlur5x5(vec2 uv, sampler2D tex, float sigma, float blurSize,  vec2 dir){

	vec3 incrementalGaussian;
 	vec4 avgValue;
 	float coefficientSum;

    getBlur(uv, tex, sigma, incrementalGaussian, avgValue, coefficientSum);
  	blur5x5();

  	return (avgValue / coefficientSum).rgb;
}


