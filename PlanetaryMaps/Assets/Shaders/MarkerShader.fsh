#version 300 es

precision highp float;

out vec4 fragmentColor;
in vec2 texCoord;

uniform sampler2D image;

void main()
{
    fragmentColor = texture(image, vec2(texCoord.x, texCoord.y));
}


