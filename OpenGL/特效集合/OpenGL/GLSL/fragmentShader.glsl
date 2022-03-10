#version 300 core

precision highp float;

out vec4 FragColor;

in vec2 TexCoord;

// 声明一个纹理采样器
uniform sampler2D texture1;
uniform sampler2D texture2;

void main()
{
    FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.3);
}
