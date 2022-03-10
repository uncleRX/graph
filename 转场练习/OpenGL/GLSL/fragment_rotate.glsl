#version 300 core
precision highp float;

out vec4 FragColor;

in vec2 Coordinate;

// 转场进度 0 - 1.0
uniform float completeness;

uniform sampler2D inputTexture1;
uniform sampler2D inputTexture2;

float PI = 3.1415926;

void main()
{
    // 假设总的旋转角度是360
    float currentAngle = completeness * PI;

    //新的纹理坐标的点为

    float x = Coordinate.x / 2.f * cos(currentAngle) - Coordinate.y / 2.f * sin(currentAngle);
    float y = Coordinate.y / 2.f * cos(currentAngle) +  Coordinate.x / 2.f * sin(currentAngle);
    
    if (completeness <= 0.5)
    {
        FragColor = texture(inputTexture1, vec2(x,y));

    }else
    {
        FragColor = texture(inputTexture2, vec2(x,y));
    }
}

