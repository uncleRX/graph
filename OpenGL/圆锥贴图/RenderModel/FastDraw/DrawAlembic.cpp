//
//  DrawAlembic.cpp
//  RenderModel
//
//  Created by 任迅 on 2022/9/7.
//

#include "DrawAlembic.hpp"

DrawAlembic::DrawAlembic(String abcPath, String m_textureImagePath) : m_abcPath(abcPath),m_textureImagePath(abcPath)
{
    this->scene = new AbcScene(abcPath);
    this->scene->setOriginTrackSize(1080, 1920);
    unsigned int VAO,VBO1,VBO2;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO1);
    glGenBuffers(1, &VBO2);
    this->VAO = VAO;
    this->VBO1 = VBO1;
    this->VBO2 = VBO2;
    
    // 初始化着色器
    this->m_shader = new Shader("/Users/renxun/Desktop/file/Repository/音视频学习/图形API/OpenGL/圆锥贴图/RenderModel/shader/simple.vs", "/Users/renxun/Desktop/file/Repository/音视频学习/图形API/OpenGL/圆锥贴图/RenderModel/shader/simple.fs");
    this->m_texture = new TextureModel(m_textureImagePath);
    bool res = m_texture->load();
    if (!res)
    {
        std::cout << "纹理加载失败" << std::endl;
        return ;
    }
}

DrawAlembic::~DrawAlembic()
{

}

void DrawAlembic::setTime(float seconds)
{
    this->scene->setTime(seconds);
}

void DrawAlembic::draw()
{
    std::vector<AbcIPolyMeshData> datas;
    this->scene->readCurrentIPolyMeshDatas(datas);
    AbcIPolyMeshData meshData = datas.front();
    glBindVertexArray(VAO);
    static bool isFirst = true;
    
    unsigned long verticeSize = meshData.vertices.size() * sizeof(float);
    unsigned long uvSize = meshData.uvs.size() * sizeof(float);
    
    int i = 1;
    for (float& y : meshData.uvs)
    {
        if(i % 2 == 0)
        {
            y = 1.0 - y;
        }
        i++;
    }
    if (isFirst)
    {
        glBindBuffer(GL_ARRAY_BUFFER, VBO1);
        glBufferData(GL_ARRAY_BUFFER, verticeSize, meshData.vertices.data(), GL_STATIC_DRAW);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
        glEnableVertexAttribArray(0);
        
        glBindBuffer(GL_ARRAY_BUFFER, VBO2);
        glBufferData(GL_ARRAY_BUFFER, uvSize, meshData.uvs.data(), GL_STATIC_DRAW);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)(0));
        glEnableVertexAttribArray(1);
        isFirst = false;
    }
    else
    {
        glBindBuffer(GL_ARRAY_BUFFER, VBO1);
        glBufferSubData(GL_ARRAY_BUFFER, 0, verticeSize, meshData.vertices.data());
        glBindBuffer(GL_ARRAY_BUFFER, VBO2);
        glBufferSubData(GL_ARRAY_BUFFER, 0, uvSize, meshData.uvs.data());
    }
    this->m_shader->use();
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, this->m_texture->textureID);
    m_shader->setInt("texture1", 0);
    glm::mat4 mvp(1.0);
    m_shader->setMat4("mvp", mvp);
    
    glBindVertexArray(this->VAO);
    glDrawArrays(GL_TRIANGLES, 0 , meshData.vertexCount);
    glBindVertexArray(0);
}
