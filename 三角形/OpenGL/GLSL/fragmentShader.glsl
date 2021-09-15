#version 300 core

precision highp float;

in vec4 color1;
out vec4 FragColor;
uniform vec4 ourColor;

void main()
{
//    FragColor = color1;
    FragColor = ourColor;
} 
