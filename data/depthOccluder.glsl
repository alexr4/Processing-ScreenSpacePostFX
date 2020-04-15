
#version 150
#ifdef GL_ES
precision highp float;
precision highp int;
#endif

uniform sampler2D texture;
uniform sampler2D depthmap;
uniform float farOcclusion;
uniform float far;
uniform float near;

in vec4 vertTexCoord;
out vec4 fragColor;

float ldepth(in float d){
	float nd = (2.0 * near) / (far + near - d * (far - near));
	return nd;
}

void main() {  
	float depth = ldepth(texture2D(depthmap, vertTexCoord.xy).r); 
    float lFarOccluder = ldepth(farOcclusion/far);
    float occluder = smoothstep(lFarOccluder*0.98, lFarOccluder, depth);

    vec4 rgbaOccluded = texture2D(texture, vertTexCoord.xy) * occluder;

	fragColor = vec4(rgbaOccluded.rgb, 1.0);
}


