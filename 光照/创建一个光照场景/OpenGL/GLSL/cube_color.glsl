#version 300 core

precision highp float;

// 法向量
in vec3 Normal;
in vec3 FragPos;

out vec4 FragColor;

uniform vec3 objectColor;
uniform vec3 lightColor;

// 光源位置
uniform vec3 lightPos;

void main()
{
    // 计算光源和片段位置之间的方向向量
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    
    // 返回连个向量的点乘结果
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;

    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * lightColor;
    
    // 最终颜色 = 环境光 + 漫反射光 + 物体本身的默认颜色
    vec3 result = (ambient + diffuse) * objectColor;
    FragColor = vec4(result, 1.0);
}

