#version 300 es

precision highp float;

out vec4 fragmentColor;
in vec2 texCoord;

uniform float edgeDimIntensity;

uniform float planetSizeMultiplier;

const float pi = 3.1415926536;

void main()
{
    float x =  texCoord.x * planetSizeMultiplier;
    float y = -texCoord.y * planetSizeMultiplier;
    
    float r = x * x + y * y;
    float dim = ((1.0 - edgeDimIntensity) + edgeDimIntensity * cos(r * pi / 2.0));
    fragmentColor.xyz = vec3(0, 0, 0);
    fragmentColor.a = dim;
}
