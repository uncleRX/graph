#version 300 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 acolor;

out vec4 outColor; //颜色输出

void main()
{
    gl_Position = vec4(aPos, 1.0);
    outColor = vec4(acolor, 1.0);
}
