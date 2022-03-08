#version 300 core

precision highp float;

// 法向量
in vec3 Normal;
out vec4 FragColor;

uniform vec3 objectColor;
uniform vec3 lightColor;

// 光源位置
uniform vec3 lightPos;



void main()
{
    
    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * lightColor;
    
    vec3 result = ambient * objectColor;
    FragColor = vec4(result, 1.0);
    
//    FragColor = vec4(lightColor * objectColor, 1.0);
}

