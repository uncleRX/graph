#version 330 core

precision highp float;

in vec2 TexCoord;
out vec4 color;

uniform sampler2D texture1;
uniform float alpha;

void main()
{
    if (alpha == 0.0)
    {
        color = vec4(0.0, 0.0, 0.0, 0.0);
    }else {
        color = texture(texture1, TexCoord);
    }
}
