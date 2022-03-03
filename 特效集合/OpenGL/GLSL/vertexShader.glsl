#version 300 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;

uniform mat4 scale;
uniform mat4 rotation;
uniform mat4 translation;

out vec2 TexCoord; // 纹理坐标输出

void main()
{
    vec4 position = vec4(aPos, 1.0);
    gl_Position = rotation * scale * translation * position;
    TexCoord = aTexCoord;
}
