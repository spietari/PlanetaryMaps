#version 300 es

precision highp float;

in vec4 position;

out vec2 texCoord;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    texCoord = textureCoordinate;
    gl_Position = modelViewProjectionMatrix * position;
}

