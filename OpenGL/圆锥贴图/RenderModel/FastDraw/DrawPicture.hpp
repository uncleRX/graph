//
//  DrawPicture.hpp
//  RenderModel
//
//  Created by 任迅 on 2022/9/7.
//

#ifndef DrawPicture_hpp
#define DrawPicture_hpp

#include <stdio.h>
#include "Depends.h"
#include "TextureModel.hpp"
#include "shader_m.h"

class DrawOnePicture {
    
public:
    String path;
    glm::mat4 mvp;
    
    DrawOnePicture(String path);
    ~DrawOnePicture();
    
    // 准备数据
    void prepare();
    
    // 绘制
    void draw();
    
private:
    TextureModel *m_texture;
    
    unsigned int VAO;
    unsigned int VBO;
    unsigned int EBO;
    Shader *m_shader;
    
    bool alreadyPrepare{false};
};


#endif /* DrawPicture_hpp */
