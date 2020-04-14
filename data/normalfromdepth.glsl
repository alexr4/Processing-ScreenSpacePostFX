//non linearized depth

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;
uniform vec2 mouse;

in vec4 vertTexCoord;
out vec4 fragColor;

vec3 getNormal(float depth, vec2 uv){
	vec2 offsety = vec2(0.0, 0.01);
	vec2 offsetx = vec2(0.01, 0.0);

	float depthoy = texture2D(texture, uv + offsety).r;
	float depthox = texture2D(texture, uv + offsetx).r;

	vec3 py = vec3(offsety, depthoy - depth);
	vec3 px = vec3(offsetx, depthox - depth);

	vec3 normal = cross(py, px);
	normal.z *= -1.0;

	return normalize(normal);
}

void main(){
	vec2 uv = vertTexCoord.xy;
	float depth = texture2D(texture, uv).r;
	vec3 norm = getNormal(depth, uv);

	fragColor = vec4(norm, 1.0);
}