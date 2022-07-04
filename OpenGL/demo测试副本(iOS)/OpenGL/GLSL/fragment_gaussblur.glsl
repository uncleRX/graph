#version 300 core

precision mediump float;
precision mediump int;

in vec2 TexCoord;

out vec4 glFragColor;
uniform sampler2D tex;
const float gaussweight[11] =
float[11](0.082607, 0.080977, 0.076276, 0.069041, 0.060049, 0.050187,
          0.040306, 0.031105, 0.023066, 0.016436, 0.011254);
void main() {
    
    vec2 wh_rcp = vec2(1.0, 1.0);
    vec2 dir_offset = vec2(1.5,1.5);
    vec2 coord = TexCoord.xy * wh_rcp;
    vec2 i_off = coord.xy - 10.0 * dir_offset;
    vec4 sum = vec4(0.);
    for (int i = -10; i < 11; i++) {
        sum += textureLod(tex, i_off, 0.0) * gaussweight[abs(i)];
        i_off += dir_offset;
    }
    glFragColor = sum;
}
