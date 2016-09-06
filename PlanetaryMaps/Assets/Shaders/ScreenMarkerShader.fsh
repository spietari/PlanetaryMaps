#version 300 es

precision highp float;

out vec4 fragmentColor;
in vec2 texCoord;

void main()
{
    fragmentColor = vec4(texCoord.x, texCoord.y, 0, 1);
}


