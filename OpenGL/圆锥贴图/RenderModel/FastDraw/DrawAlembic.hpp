//
//  DrawAlembic.hpp
//  RenderModel
//
//  Created by 任迅 on 2022/9/7.
//

#ifndef DrawAlembic_hpp
#define DrawAlembic_hpp

#include <stdio.h>
#include "Depends.h"
#include "AbcScene.hpp"
#include "TextureModel.hpp"
#include "shader_m.h"

using namespace AbcModule;

class DrawAlembic {
    
public:
    String m_abcPath;
    String m_textureImagePath;
    
    DrawAlembic(String abcPath, String m_textureImagePath);
    ~DrawAlembic();
    
    void setTime(float seconds);
    void draw();
    
    
private:
    AbcScene *scene;
    
    TextureModel *m_texture;
    unsigned int VAO;
    unsigned int VBO1;
    unsigned int VBO2;
    Shader *m_shader;
};

#endif /* DrawAlembic_hpp */
