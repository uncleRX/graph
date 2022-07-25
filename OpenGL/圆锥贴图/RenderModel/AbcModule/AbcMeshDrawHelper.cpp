//
//  MeshDrawHelper.cpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/20.
//

#include "AbcMeshDrawHelper.hpp"

#include "TextureModel.hpp"


using namespace AbcModule;


//GLRender::GLRender
//{
//    
//}
//
//GLRender::~GLRender()
//{
//    
//}

//-*****************************************************************************
MeshDrawHelper::MeshDrawHelper()
{
    makeInvalid();
    
    // 初始化数据
    glEnable(GL_DEPTH_TEST);
    unsigned int VAO,VBO,VBO1,EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &VBO1);
    glGenBuffers(1, &EBO);
    this->m_VAO = VAO;
    this->m_VBO = VBO;
    this->m_EBO = EBO;
    this->m_VBO1 = VBO1;

    // 初始化着色器
    this->ourShader = new Shader("/Users/renxun/Desktop/file/Repository/音视频学习/图形API/OpenGL/圆锥贴图/RenderModel/shader/simple.vs", "/Users/renxun/Desktop/file/Repository/音视频学习/图形API/OpenGL/圆锥贴图/RenderModel/shader/simple.fs");
    this->texture = new TextureModel("/Users/renxun/Desktop/file/Repository/音视频学习/图形API/OpenGL/绘制立方体/OpenGL/王路飞.jpeg");
    bool res = texture->load();
    if (!res)
    {
        std::cout << "纹理加载失败" << std::endl;
        return ;
    }
    ourShader->use();
    ourShader->setInt("texture1", 0);
    
//    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
}

//-*****************************************************************************
MeshDrawHelper::~MeshDrawHelper()
{
    makeInvalid();
    delete this->texture;
    delete this->ourShader;
    this->texture = nullptr;
    this->ourShader = nullptr;
}

//-*****************************************************************************

void MeshDrawHelper::update( P3fArraySamplePtr iP,
                            V3fArraySamplePtr iN,
                            Int32ArraySamplePtr iIndices,
                            Int32ArraySamplePtr iCounts,
                            std::vector<size_t> uv_idxs,
                            std::vector<Imath::Vec2<float>> uv_coords,
                            Abc::Box3d iBounds
                            )
{
    // Before doing a ton, just have a quick look.
    if ( m_meshP && iP &&
         ( m_meshP->size() == iP->size() ) &&
         m_meshIndices &&
         ( m_meshIndices == iIndices ) &&
         m_meshCounts &&
         ( m_meshCounts == iCounts ) )
    {
        if ( m_meshP == iP )
        {
            updateNormals( iN );
        }
        else
        {
            update( iP, iN );
        }
        return;
    }

    // Okay, if we're here, the indices are not equal or the counts
    // are not equal or the P-array size changed.
    // So we can clobber those three, but leave N alone for now.
    m_meshP = iP;
    m_meshIndices = iIndices;
    m_meshCounts = iCounts;
    m_uvCoords = uv_coords;
    m_uvIndices = uv_idxs;
    m_triangles.clear ();

    // Check stuff.
    if ( !m_meshP ||
         !m_meshIndices ||
         !m_meshCounts )
    {
        std::cerr << "Mesh update quitting because no input data"
                  << std::endl;
        makeInvalid();
        return;
    }

    // Get the number of each thing.
    size_t numFaces = m_meshCounts->size();
    size_t numIndices = m_meshIndices->size();
    size_t numPoints = m_meshP->size();
    if ( numFaces < 1 ||
         numIndices < 1 ||
         numPoints < 1 )
    {
        // Invalid.
        std::cerr << "Mesh update quitting because bad arrays"
                  << ", numFaces = " << numFaces
                  << ", numIndices = " << numIndices
                  << ", numPoints = " << numPoints
                  << std::endl;
        makeInvalid();
        return;
    }

    // Make triangles.
    size_t faceIndexBegin = 0;
    size_t faceIndexEnd = 0;
    for ( size_t face = 0; face < numFaces; ++face )
    {
        faceIndexBegin = faceIndexEnd;
        size_t count = (*m_meshCounts)[face];
        faceIndexEnd = faceIndexBegin + count;

        // Check this face is valid
        if ( faceIndexEnd > numIndices ||
             faceIndexEnd < faceIndexBegin )
        {
            std::cerr << "Mesh update quitting on face: "
                      << face
                      << " because of wonky numbers"
                      << ", faceIndexBegin = " << faceIndexBegin
                      << ", faceIndexEnd = " << faceIndexEnd
                      << ", numIndices = " << numIndices
                      << ", count = " << count
                      << std::endl;

            // Just get out, make no more triangles.
            break;
        }

        // Checking indices are valid.
        bool goodFace = true;
        for ( size_t fidx = faceIndexBegin;
              fidx < faceIndexEnd; ++fidx )
        {
            if ( ( size_t ) ( (*m_meshIndices)[fidx] ) >= numPoints )
            {
                std::cout << "Mesh update quitting on face: "
                          << face
                          << " because of bad indices"
                          << ", indexIndex = " << fidx
                          << ", vertexIndex = " << (*m_meshIndices)[fidx]
                          << ", numPoints = " << numPoints
                          << std::endl;
                goodFace = false;
                break;
            }
        }

        // Make triangles to fill this face.
        if ( goodFace && count > 2 )
        {
            m_triangles.push_back(
                Tri( ( unsigned int )(*m_meshIndices)[faceIndexBegin+0],
                     ( unsigned int )(*m_meshIndices)[faceIndexBegin+1],
                     ( unsigned int )(*m_meshIndices)[faceIndexBegin+2] ) );
            for ( size_t c = 3; c < count; ++c )
            {
                m_triangles.push_back(
                    Tri( ( unsigned int )(*m_meshIndices)[faceIndexBegin+0],
                         ( unsigned int )(*m_meshIndices)[faceIndexBegin+c-1],
                         ( unsigned int )(*m_meshIndices)[faceIndexBegin+c]
                         ) );
            }
        }
    }

    // Cool, we made triangles.
    // Pretend the mesh is made...
    m_valid = true;

    // And now update just the P and N, which will update bounds
    // and calculate new normals if necessary.

    if ( iBounds.isEmpty() )
    {
        computeBounds();
    }
    else
    {
        m_bounds = iBounds;
    }

    updateNormals( iN );

    // And that's it.
}

//-*****************************************************************************
void MeshDrawHelper::update( P3fArraySamplePtr iP,
                            V3fArraySamplePtr iN,
                            Abc::Box3d iBounds )
{
    // Check validity.
    if ( !m_valid || !iP || !m_meshP ||
         ( iP->size() != m_meshP->size() ) )
    {
        makeInvalid();
        return;
    }

    // Set meshP
    m_meshP = iP;

    if ( iBounds.isEmpty() )
    {
        computeBounds();
    }
    else
    {
        m_bounds = iBounds;
    }

    updateNormals( iN );
    
    
}

//-*****************************************************************************
void MeshDrawHelper::updateNormals( V3fArraySamplePtr iN )
{
    if ( !m_valid || !m_meshP )
    {
        makeInvalid();
        return;
    }

    // Now see if we need to calculate normals.
    if ( ( m_meshN && iN == m_meshN ) ||
         ( isConstant() && m_customN.size() > 0 ) )
    {
        return;
    }

    size_t numPoints = m_meshP->size();
    m_meshN = iN;
    m_customN.clear();

    // Right now we only handle "vertex varying" normals,
    // which have the same cardinality as the points
    if ( !m_meshN || m_meshN->size() != numPoints )
    {
        // Make some custom normals.
        m_meshN.reset();
        m_customN.resize( numPoints );
        std::fill( m_customN.begin(), m_customN.end(), V3f( 0.0f ) );

        for ( size_t tidx = 0; tidx < m_triangles.size(); ++tidx )
        {
            const Tri &tri = m_triangles[tidx];

            const V3f &A = (*m_meshP)[tri[0]];
            const V3f &B = (*m_meshP)[tri[1]];
            const V3f &C = (*m_meshP)[tri[2]];

            V3f AB = B - A;
            V3f AC = C - A;

            V3f wN = AC.cross( AB );
            m_customN[tri[0]] += wN;
            m_customN[tri[1]] += wN;
            m_customN[tri[2]] += wN;
        }

        // Normalize normals.
        for ( size_t nidx = 0; nidx < numPoints; ++nidx )
        {
            m_customN[nidx].normalize();
        }
    }
}


//-*****************************************************************************
void MeshDrawHelper::draw() const
{
    if ( !m_valid || m_triangles.size() < 1 || !m_meshP )
    {
        return;
    }
    int numPoints = m_meshP->size();
    int indicesCount = m_triangles.size()* 3;
    GLfloat vertices[indicesCount * 3];
    GLfloat coords[indicesCount * 2];
    
    int vvi = 0;
    int ci = 0;
    int uvi = 0;
    
    float cMaxX, cMaxY, cMinX, cMinY;
    cMaxX = -1.0;
    cMaxY = -1.0;
    cMinX = 1.0;
    cMinY = 1.0;
    
    for (auto value : this->m_uvCoords) {
        if (value.x < cMinX)
        {
            cMinX = value.x;
        }
        if (value.x > cMaxX) {
            cMaxX = value.x;
        }
        if (value.y < cMinY)
        {
            cMinY = value.y;
        }
        if (value.y > cMaxY)
        {
            cMaxY = value.y;
        }
    }
    float cXLength = cMaxX - cMinX;
    float cYLength = cMaxY - cMinY;
    
    // 处理三角形数据
    for (int i = 0; i < m_triangles.size(); i++) {
        auto value = m_triangles[i];
        
        const V3f &p1 = (*m_meshP)[value.x];
        vertices[vvi] = p1.x;
        vertices[vvi+1] = p1.y;
        vertices[vvi+2] = p1.z;
        
        coords[ci] = (this->m_uvCoords[uvi].x - cMinX) / cXLength;
        coords[ci+1] = (this->m_uvCoords[uvi].y - cMinY) / cYLength;
        vvi += 3;
        uvi += 1;
        ci += 2;

        const V3f &p2 = (*m_meshP)[value.y];
        vertices[vvi] = p2.x ;
        vertices[vvi+1] = p2.y ;
        vertices[vvi+2] = p2.z;
        
        coords[ci] = (this->m_uvCoords[uvi].x - cMinX) / cXLength;
        coords[ci+1] = (this->m_uvCoords[uvi].y - cMinY) / cYLength;
        vvi += 3;
        uvi += 1;
        ci += 2;

        const V3f &p3 = (*m_meshP)[value.z];
        vertices[vvi] = p3.x;
        vertices[vvi+1] = p3.y ;
        vertices[vvi+2] = p3.z;
        
        coords[ci] = (this->m_uvCoords[uvi].x - cMinX) / cXLength;
        coords[ci+1] = (this->m_uvCoords[uvi].y - cMinY) / cYLength;
        vvi += 3;
        uvi += 1;
        ci += 2;

    }
    
    glBindVertexArray(m_VAO);

    static bool isFirst = true;
    if (isFirst)
    {
        glBindBuffer(GL_ARRAY_BUFFER, m_VBO);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
        glEnableVertexAttribArray(0);
        
        glBindBuffer(GL_ARRAY_BUFFER, m_VBO1);
        glBufferData(GL_ARRAY_BUFFER, sizeof(coords), coords, GL_STATIC_DRAW);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)(0));
        glEnableVertexAttribArray(1);
        isFirst = false;
    }
    else
    {
        glBindBuffer(GL_ARRAY_BUFFER, m_VBO);
        glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertices), vertices);

        glBindBuffer(GL_ARRAY_BUFFER, m_VBO1);
        glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(coords), coords);
    }
    
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, this->texture->textureID);

    this->ourShader->use();
    glBindVertexArray(this->m_VAO);
    glDrawArrays(GL_TRIANGLES, 0 , indicesCount);
//        glDrawElements(GL_TRIANGLES, indicesCount, GL_UNSIGNED_INT, 0);
}

//-*****************************************************************************
void MeshDrawHelper::makeInvalid()
{
    m_meshP.reset();
    m_meshN.reset();
    m_meshIndices.reset();
    m_meshCounts.reset();
    m_customN.clear();
    m_valid = false;
    m_bounds.makeEmpty();
    m_triangles.clear();
}

//-*****************************************************************************
void MeshDrawHelper::computeBounds()
{
    m_bounds.makeEmpty();
    if ( m_meshP )
    {
        size_t numPoints = m_meshP->size();
        for ( size_t p = 0; p < numPoints; ++p )
        {
            const V3f &P = (*m_meshP)[p];
            m_bounds.extendBy( V3d( P.x, P.y, P.z ) );
        }
    }
}
