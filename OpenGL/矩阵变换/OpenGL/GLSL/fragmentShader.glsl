#version 300 core

precision highp float;

out vec4 FragColor;

in vec4 outColor;
in vec2 TexCoord;

// 声明一个纹理采样器
uniform sampler2D texture1;
uniform sampler2D texture2;

void main()
{
    //根据第三个参数进行线性插值。如果第三个值是0.0，它会返回第一个输入；如果是1.0，会返回第二个输入值。0.2会返回80%的第一个输入颜色和20%的第二个输入颜色，即返回两个纹理的混合色
    FragColor = mix(texture(texture1, TexCoord),texture(texture2, TexCoord), 0.2);
    
}
