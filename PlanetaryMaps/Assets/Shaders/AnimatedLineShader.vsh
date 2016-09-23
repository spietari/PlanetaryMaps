#version 300 es

precision highp float;

in vec4 position;
in vec2 textureCoordinate;

out vec2 texCoord;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    texCoord = textureCoordinate;
    gl_Position = modelViewProjectionMatrix * position;
}

