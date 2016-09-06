#version 300 es

precision highp float;

in vec4 position;
in vec3 normal;

uniform float scale;
uniform mat4 modelViewProjectionMatrix;

void main()
{
    gl_Position = modelViewProjectionMatrix * (position + scale * vec4(normal, 0.0));
}

