#version 300 es

precision highp float;

out vec4 fragmentColor;

uniform vec4 color;

void main()
{
    fragmentColor = color;
}


