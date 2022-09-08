//
//  MeshDrawHelper.cpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/20.
//

#include "AbcMeshDrawHelper.hpp"

using namespace AbcModule;

//-*****************************************************************************
MeshDrawHelper::MeshDrawHelper()
{
    makeInvalid();
}

//-*****************************************************************************
MeshDrawHelper::~MeshDrawHelper()
{
    makeInvalid();
}

//-*****************************************************************************

void MeshDrawHelper::update(P3fArraySamplePtr iP,
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
    m_valid = true;
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

AbcIPolyMeshData MeshDrawHelper::getCurrentIPolyMeshData()
{
    AbcIPolyMeshData meshData;
    // 更新数据
    if ( !m_valid || m_triangles.size() < 1 || !m_meshP )
    {
        return meshData;
    }
    int numPoints = m_meshP->size();
    int indicesCount = m_triangles.size() * 3;
    
    meshData.vertices.resize(indicesCount * 3);
    meshData.uvs.resize(indicesCount * 2);
  
//    float cMaxX, cMaxY, cMinX, cMinY;
//    cMaxX = -1.0;
//    cMaxY = -1.0;
//    cMinX = 1.0;
//    cMinY = 1.0;
//
//    for (auto value : this->m_uvCoords) {
//        if (value.x < cMinX)
//        {
//            cMinX = value.x;
//        }
//        if (value.x > cMaxX) {
//            cMaxX = value.x;
//        }
//        if (value.y < cMinY)
//        {
//            cMinY = value.y;
//        }
//        if (value.y > cMaxY)
//        {
//            cMaxY = value.y;
//        }
//    }
//    float cXLength = cMaxX - cMinX;
//    float cYLength = cMaxY - cMinY;

    int uvi = 0;
    int vi = 0;
    int uvsI = 0;

    // 处理三角形数据
    for (int i = 0; i < m_triangles.size(); i++) {
        auto value = m_triangles[i];

        const V3f &p1 = (*m_meshP)[value.x];
        meshData.vertices[vi] = (p1.x);
        meshData.vertices[vi + 1] = (p1.y);
        meshData.vertices[vi + 2] = (p1.z);
        meshData.uvs[uvsI] = this->m_uvCoords[uvi].x;
        meshData.uvs[uvsI +1] = this->m_uvCoords[uvi].y;
        uvi += 1;
        vi += 3;
        uvsI += 2;
        
        const V3f &p2 = (*m_meshP)[value.y];
        meshData.vertices[vi] = (p2.x);
        meshData.vertices[vi + 1] = (p2.y);
        meshData.vertices[vi + 2] = (p2.z);
        meshData.uvs[uvsI] = this->m_uvCoords[uvi].x;
        meshData.uvs[uvsI + 1] = this->m_uvCoords[uvi].y;
        
        uvi += 1;
        vi += 3;
        uvsI += 2;
        
        const V3f &p3 = (*m_meshP)[value.z];
        meshData.vertices[vi] = p3.x;
        meshData.vertices[vi + 1] = p3.y;
        meshData.vertices[vi + 2] = p3.z;
        meshData.uvs[uvsI] = this->m_uvCoords[uvi].x;
        meshData.uvs[uvsI +1]= this->m_uvCoords[uvi].y;
        uvi += 1;
        vi += 3;
        uvsI += 2;
    }
    meshData.vertexCount = indicesCount;
    meshData.uvsCount = indicesCount;
    // TODO: 待实现
    meshData.frame = 0;
    meshData.name = "";
    return meshData;
}

//-*****************************************************************************
void MeshDrawHelper::draw() const
{

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
