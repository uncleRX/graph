#version 300 core

in vec3 aPos;
in vec2 aTexCoord;
out vec2 TexCoord; // 纹理坐标输出

uniform mat4 transform;

void main()
{
    gl_Position = transform * vec4(aPos, 1.0);
    TexCoord = aTexCoord;
}
