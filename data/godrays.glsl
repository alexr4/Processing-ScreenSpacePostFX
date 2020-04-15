
#version 150
#ifdef GL_ES
precision highp float;
precision highp int;
#endif


uniform sampler2D texture;
uniform vec3  lightPosition;
uniform float exposure = 1.0;
uniform float decay = 0.5;
uniform float density = 0.5;
uniform float weight = 0.5;
uniform float minSunDisk = 0.5;
uniform vec2 resolution;
uniform vec2 mouse;
const int NUM_SAMPLES = 100;

in vec4 vertTexCoord;
out vec4 fragColor;

void main()
{	
    vec2 lightPositionOnScreen = lightPosition.xy;
    lightPositionOnScreen.y = 1.0 - lightPositionOnScreen.y;
    vec2 deltaTextCoord = vec2(vertTexCoord.xy - lightPositionOnScreen.xy);
    float dist = 1.0 - length(deltaTextCoord);
    dist = smoothstep(minSunDisk, 1.0, dist);
    vec2 textCoo = vertTexCoord.xy;
    deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
    float illuminationDecay = 1.0;

    for(int i=0; i < NUM_SAMPLES ; i++)
    {
            textCoo -= deltaTextCoord;
            vec4 sample = texture2D(texture, textCoo);
    
            sample *= illuminationDecay * weight;

            fragColor += sample;

            illuminationDecay *= decay;
    }
    fragColor *= exposure * dist;
}
