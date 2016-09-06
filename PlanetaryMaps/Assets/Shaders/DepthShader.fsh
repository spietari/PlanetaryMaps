#version 300 es

precision highp float;

in vec2 texCoord;
out vec4 fragmentColor;

uniform vec4 planetBaseColor;
uniform vec4 haloBaseColor;

uniform float planetSizeMultiplier;

void main()
{
    float x =  texCoord.x * planetSizeMultiplier;
    float y = -texCoord.y * planetSizeMultiplier;
    
    float r = x * x + y * y;
    
    float depth = step(1.0, r);

    // Calculate the amount we are between the planet and the edge of the plane
    // and modulate the color with that value. Sqrt could be omitted but then the
    // halo is not so nice.
    float halo = 1.0 - (1.0 / (planetSizeMultiplier - 1.0)) * (sqrt(x * x + y * y) - 1.0);
    halo = clamp(halo, 0.0, 1.0);
    
    fragmentColor = (1.0 - depth) * planetBaseColor + depth * haloBaseColor * halo;
    gl_FragDepth = depth;
}


