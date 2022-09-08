#version 330 core

precision highp float;

out vec4 FragColor;

in vec2 TexCoord;

uniform sampler2D texture1;
uniform sampler2D texture2;

void main()
{
//    FragColor = texture(texture2, TexCoord);
    FragColor = vec4(1.0, 0.4, 0.4, 1.0);
}
