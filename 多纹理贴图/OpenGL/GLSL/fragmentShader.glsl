#version 300 core

precision highp float;

out vec4 FragColor;

in vec4 outColor;
in vec2 TexCoord;

// 声明一个纹理采样器
uniform sampler2D ourTexture;

void main()
{
    FragColor = texture(ourTexture, TexCoord);
//    FragColor = texture(ourTexture, gl_FragCoord.xy / vec2(375.0, 664.0));
}
