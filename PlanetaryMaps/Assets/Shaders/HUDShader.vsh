#version 300 es

precision highp float;

in vec4 position;
in vec2 textureCoordinate;

out vec2 texCoord;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    texCoord = vec2(0.5 * (textureCoordinate.x + 1.0), 0.5 * (textureCoordinate.y + 1.0));
    gl_Position = modelViewProjectionMatrix * position;
}

