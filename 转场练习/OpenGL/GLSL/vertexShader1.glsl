#version 300 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;

out vec4 outColor; // 向片段着色器输出一个颜色

void main()
{
    gl_Position = vec4(aPos, 1.0);
    outColor = vec4(aColor, 1.0);
}
