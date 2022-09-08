//
//  TextureModel.cpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/21.
//

#include <stdio.h>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#include "TextureModel.hpp"

using String = std::string;

TextureModel::TextureModel(String path) : path(path), width(0), height(0), textureID(-1), isVaild(false)
{
    
}

TextureModel::~TextureModel()
{
    
}

bool TextureModel::load()
{
    if (this->path.empty())
    {
        std::cout << "TextureModel: 路径为空" << std::endl;
        return false;
    }
    GLuint texture;
    static int index = 0;
    glGenTextures(1, &texture);
    // 绑定之前需要先激活
    glBindTexture(GL_TEXTURE_2D, texture);

    // 为当前绑定的纹理对象设置环绕、过滤方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // 1 - 生成纹理
    int imageWidth, imageHeight, imageChannels;
    
//    stbi_set_flip_vertically_on_load(true);

    stbi_convert_iphone_png_to_rgb(true);
    unsigned char *imageData = stbi_load(this->path.c_str(), &imageWidth, &imageHeight, &imageChannels, STBI_rgb_alpha);
    if (imageData)
    {
        this->isVaild = true;
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
        glGenerateMipmap(GL_TEXTURE_2D);
        stbi_image_free(imageData);
    }
    else
    {
        this->isVaild = false;
        std::cout << "TextureModel: 加载纹理失败" << this->path << std::endl;
        glBindTexture(GL_TEXTURE_2D, 0);
        return false;
    }
    this->width = imageWidth;
    this->height = imageHeight;
    this->textureID = texture;
    index++;
    glBindTexture(GL_TEXTURE_2D, 0);
    return true;
}

bool TextureModel::update(String path)
{
    if (path.empty())
    {
        return false;
    }
    this->path = path;
    glBindTexture(GL_TEXTURE_2D, this->textureID);

    std::cout << path << std::endl;
    // 1 - 更新纹理
    int imageWidth, imageHeight, imageChannels;
    unsigned char *imageData = stbi_load(this->path.c_str(), &imageWidth, &imageHeight, &imageChannels, STBI_rgb_alpha);
    if (imageData)
    {
        this->isVaild = true;
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);

//        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, imageWidth, imageHeight
//                        , GL_RGBA, GL_UNSIGNED_BYTE, imageData);
        stbi_image_free(imageData);
    }
    else
    {
        this->isVaild = false;
        std::cout << "TextureModel: 加载纹理失败" << this->path << std::endl;
        glBindTexture(GL_TEXTURE_2D, 0);
        return false;
    }
    return true;
}
