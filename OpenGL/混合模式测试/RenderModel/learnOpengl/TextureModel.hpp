//
//  TextureModel.hpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/1.
//

#ifndef TextureModel_hpp
#define TextureModel_hpp



#include <stdio.h>
#include <string>
#include <iostream>
#include <glad/glad.h>


using String = std::string;

class TextureModel {
    
public:
    TextureModel(String path);
    
    // 不激活纹理
    bool load();
    
    ~TextureModel();
    
    bool update(String path);
    
    int width;
    int height;
    int32_t textureID;
private:
    bool isVaild = false;
    String path;
};

#endif /* TextureModel_hpp */
