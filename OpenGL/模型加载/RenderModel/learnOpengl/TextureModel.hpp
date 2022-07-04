//
//  TextureModel.hpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/1.
//

#ifndef TextureModel_hpp
#define TextureModel_hpp

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#include <stdio.h>
#include <string>
#include <iostream>

using String = std::string;

class TextureModel {
    
public:
    TextureModel(String path) : path(path), width(0), height(0), textureID(-1), isVaild(false)
    {
        
    }

    
    // 不激活纹理
    bool load()
    {
        if (this->path.empty())
        {
            std::cout << "TextureModel: 路径为空" << std::endl;
            return false;
        }
        GLuint texture;
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
//        stbi_set_flip_vertically_on_load(true);
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
            return false;
        }
        
        this->width = imageWidth;
        this->height = imageHeight;
        this->textureID = texture;
        return true;
    }
    
    ~TextureModel() {}
    
    int width;
    int height;
    int32_t textureID;
private:
    bool isVaild = false;
    String path;
};



#endif /* TextureModel_hpp */
