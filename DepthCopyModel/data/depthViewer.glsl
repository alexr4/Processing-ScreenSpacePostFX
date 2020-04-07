
uniform sampler2D depthTexture;

varying vec4 vertTexCoord;


void main() {  
	vec4 depth = texture2D(depthTexture, vec2(vertTexCoord.s, 1.0-vertTexCoord.t)); 
	gl_FragColor = depth;
}


