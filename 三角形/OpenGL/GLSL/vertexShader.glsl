#version 300 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec4 color;

out vec4 color1;

void main()
{
    color1 = vec4(1.0,0.0,0.0,1.0);
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}
