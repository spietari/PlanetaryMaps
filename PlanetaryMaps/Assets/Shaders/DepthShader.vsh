#version 300 es

precision highp float;

in vec4 position;
in vec2 textureCoordinate;

uniform mat4 modelViewProjectionMatrix;

out vec2 texCoord;

void main()
{
    texCoord = textureCoordinate;
    gl_Position = modelViewProjectionMatrix * position;
}
