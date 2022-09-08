//
//  DrawPicture.cpp
//  RenderModel
//
//  Created by 任迅 on 2022/9/7.
//

#include "DrawPicture.hpp"
#include "Depends.h"

DrawOnePicture::DrawOnePicture(String path): path(path), mvp(glm::mat4(1.0f))
{
    this->m_shader = new Shader("/Users/renxun/Desktop/file/Repository/音视频学习/图形API/OpenGL/圆锥贴图/RenderModel/shader/simple.vs", "/Users/renxun/Desktop/file/Repository/音视频学习/图形API/OpenGL/圆锥贴图/RenderModel/shader/simple.fs");
    this->m_texture = new TextureModel(path);
}

DrawOnePicture::~DrawOnePicture()
{
    
}

void DrawOnePicture::prepare()
{
    if (this->alreadyPrepare)
    {
        return;
    }
    this->alreadyPrepare = true;
    this->m_texture->load();
    unsigned int VAO,VBO,EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);
    this->VAO = VAO;
    this->VBO = VBO;
    this->EBO = EBO;
    
    float vertices[] = {
          // Positions
        1.0,  1.0, -1.0f,   1.0f, 1.0f, // Top Right
        1.0, -1.0, -1.0f,   1.0f, 0.0f, // Bottom Right
        -1.0, -1.0, -1.0f,   0.0f, 0.0f, // Bottom Left
        -1.0,  1.0, -1.0f,   0.0f, 1.0f  // Top Left
      };

    int indices[] = {
        0, 1, 3,
        1, 2, 3
    };
    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
    glBindVertexArray(0);
}

void DrawOnePicture::draw()
{
    this->m_shader->use();
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, this->m_texture->textureID);
    m_shader->setInt("texture1", 0);
    m_shader->setMat4("mvp", mvp);
    glBindVertexArray(this->VAO);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);
}

