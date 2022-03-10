#version 300 core

precision highp float;

in vec2 TexCoord;
out vec4 FragColor;

uniform sampler2D inputTexture;
uniform vec2 texSize;
uniform vec2 mosaicSize;

void main()
{
    // 1. 纹理坐标是0～1， 先将纹理坐标扩大假定纹理大小
    vec2 intXY = vec2(TexCoord.x * texSize.x, TexCoord.y * texSize.y);
    
    // 2. 计算得到假定纹理大小下当前纹理坐标所处色块的起始点位置
    vec2 XYMosaic = floor(intXY/mosaicSize) * mosaicSize;
    
    // 3. 在将起始点位置换算成标准0～1的范围
    vec2 UVMosaic = XYMosaic / texSize;
    
    FragColor = texture(inputTexture, UVMosaic);
    
}
