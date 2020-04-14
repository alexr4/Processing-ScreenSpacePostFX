//non linearized depth

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform mat4 projmat;
uniform sampler2D texture;
uniform vec2 mouse;
uniform float near = 10.0;
uniform float far = 500;

in vec4 vertTexCoord;
out vec4 fragColor;

float ldepth(in float d){
	float nd = (2.0 * near) / (far + near - d * (far - near));
	return nd;
}

vec3 reconstructPosition(in float z, in vec2 uv, mat4 projmat)
{
//from https://stackoverflow.com/questions/11277501/how-to-recover-view-space-position-given-view-space-depth-value-and-ndc-xy
    mat4 inversePrjMat = inverse(projmat);
    vec4 viewPosH      = inversePrjMat * vec4(uv.x, uv.y,  z * 2.0 - 1.0, 1.0 );
    vec3 viewPos       = viewPosH.xyz / viewPosH.w;

    return viewPos;
}
void main(){
	vec2 uv = vertTexCoord.xy;

  float offset = 0.01;
  vec2 offsetx = vec2(1.0, 0.0) * offset;
  vec2 offsety = vec2(0.0, 1.0) * offset;

	float depth   = texture2D(texture, uv).r;
	float depthpx = texture2D(texture, uv + offsetx).r;
	float depthpy = texture2D(texture, uv + offsety).r;
	float depthmx = texture2D(texture, uv - offsetx).r;
	float depthmy = texture2D(texture, uv - offsety).r;

  float diffPX = abs(depth - depthpx);
  float diffMX = abs(depth - depthmx);

  float diffPY = abs(depth - depthpy);
  float diffMY = abs(depth - depthmy);


  vec3 ecVertex = reconstructPosition(depth, uv * 2.0 - 1.0, projmat);
  vec3 A        = reconstructPosition(depthpx, (uv + offsetx) * 2.0 - 1.0, projmat);
  vec3 B        = reconstructPosition(depthpy, (uv + offsety) * 2.0 - 1.0, projmat);
  vec3 C        = reconstructPosition(depthmx, (uv - offsetx) * 2.0 - 1.0, projmat);
  vec3 D        = reconstructPosition(depthmy, (uv - offsety) * 2.0 - 1.0, projmat);
  // vec3 normalAB = normalize(-cross(A - ecVertex, B - ecVertex));
  // vec3 normalCD = normalize(-cross(C - ecVertex, D - ecVertex));
  // vec3 normalAD = normalize(cross(A - ecVertex, D - ecVertex));
  // vec3 normalCB = normalize(cross(C - ecVertex, B - ecVertex));
  vec3 normalAB = normalize( cross(B - ecVertex, A - ecVertex));
  vec3 normalCD = normalize( cross(D - ecVertex, C - ecVertex));
  vec3 normalAD = normalize(-cross(D - ecVertex, A - ecVertex));
  vec3 normalCB = normalize(-cross(B - ecVertex, C - ecVertex));

  //average
  vec3 normal = (normalAB + normalCB + normalAD + normalCB) / 4.0;


  vec3 PX = diffPX < diffMX ? A : C;
  vec3 PY = diffPY < diffMY ? B : D;

  // normal = normalize(cross(ecVertex - PY, ecVertex - PX));

	fragColor = vec4(normal, 1.0);
}