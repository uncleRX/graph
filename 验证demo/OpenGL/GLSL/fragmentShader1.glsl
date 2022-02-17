#version 300 core

precision highp float;

in vec4 outColor;
out vec4 FragColor;

void main()
{
    FragColor = outColor;
}
