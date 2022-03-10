#version 300 core
precision highp float;

out vec4 FragColor;

in vec2 Coordinate;

// 转场进度 0 - 1.0
uniform float completeness;

uniform sampler2D inputTexture1;
uniform sampler2D inputTexture2;

void main()
{
    if (Coordinate.y < completeness)
    {
        FragColor = texture(inputTexture1, Coordinate);
    }else
    {
        FragColor = texture(inputTexture2, Coordinate);
    }
}

