//non linearized depth

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform mat4 InvVP;
uniform sampler2D texture;
uniform vec2 mouse;

in vec4 vertTexCoord;
out vec4 fragColor;

vec3 reconstructPosition(in vec2 uv, in float z, in mat4 InvVP)
{
  float x = uv.x * 2.0f - 1.0f;
  float y = (1.0 - uv.y) * 2.0f - 1.0f;
  vec4 position_s = vec4(x, y, z, 1.0f);
  vec4 position_v = InvVP * position_s;
  return position_v.xyz / position_v.w;
}

void main(){
	vec2 uv = vertTexCoord.xy;
	float depth = texture2D(texture, uv).r;
    vec3 P = reconstructPosition(uv, depth, InvVP);
    vec3 normal = normalize(cross(dFdx(P), dFdy(P)));
	fragColor = vec4(normal, 1.0);
}