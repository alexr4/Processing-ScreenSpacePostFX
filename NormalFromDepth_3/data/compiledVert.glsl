/*
 Porcessing pixel shader by bonjour-lab
  www.bonjour-lab.com
*/
//Matrix elements
#version 150

uniform mat4 modelviewMatrix;
uniform mat4 transformMatrix;
uniform mat3 normalMatrix;
uniform mat4 texMatrix;
uniform mat4 shadowTransform; 
uniform vec3 lightDirection;

//Attributes (vertex, normal, color...)
attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;
attribute vec2 texCoord;

//Material attribute
attribute vec4 ambient;
attribute vec4 specular;
attribute vec4 emissive;
attribute float shininess;

//Out varibale to fragment → need to be set into "out"
out vec4 vertColor;
out vec4 backVertColor;
out vec4 vertTexCoord;
out vec3 ecNormal;
out vec4 ecVertex;
//material
out vec4 vambient;
out vec4 vspecular;
out vec4 vemissive;
out float vshininess;



void main() {
  // Vertex in clip coordinates
  gl_Position = transformMatrix * position;

  //Define ecNormal & ecVertex
  ecNormal = normalize(normalMatrix * normal);
  ecVertex = modelviewMatrix * position;

  //define vertex color and material
  vertColor = color;
  backVertColor = color;

  vambient = ambient;
  vspecular = specular;
  vemissive = emissive;
  vshininess = shininess;

  //Define vertTexCoord
  vertTexCoord = texMatrix * vec4(texCoord, 1.0, 1.0);
}
