//
//  MeshDrawHelper.hpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/20.
//

#ifndef MeshDrawHelper_hpp
#define MeshDrawHelper_hpp

#include <stdio.h>
#include "Alembic/Abc/All.h"
#include "Alembic/AbcCoreFactory/All.h"
#include "Alembic/AbcCoreOgawa/All.h"
#include "Alembic/AbcCoreAbstract/All.h"
#include "Alembic/AbcGeom/All.h"
#include "AbcIPolyMeshData.h"

namespace Abc = Alembic::Abc;
using namespace Abc;

namespace AbcModule
{

class MeshDrawHelper : private Alembic::Util::noncopyable
{

public:
    MeshDrawHelper();
    
    ~MeshDrawHelper();
    
    // This is a "full update" of all parameters.
    // If N is empty, normals will be computed.
    void update(P3fArraySamplePtr iP,
                V3fArraySamplePtr iN,
                Int32ArraySamplePtr iIndices,
                Int32ArraySamplePtr iCounts,
                std::vector<size_t> uv_idxs,
                std::vector<Imath::Vec2<float>> uv_coords,
                Abc::Box3d iBounds
                );
    
    // Update just positions and possibly normals
    void update( P3fArraySamplePtr iP,
                V3fArraySamplePtr iN,
                Abc::Box3d iBounds = Abc::Box3d() );
    
    // Update just normals
    void updateNormals( V3fArraySamplePtr iN );
    
    // This returns validity.
    bool valid() const { return m_valid; }
    
    // This returns constancy.
    bool isConstant() const { return m_isConstant; }
    void setConstant( bool isConstant = true ) { m_isConstant = isConstant; }

    AbcIPolyMeshData getCurrentIPolyMeshData();

    void draw() const;
    
    // This is a weird thing. Just makes the helper invalid
    // by nulling everything out. For internal use.
    void makeInvalid();
    
    // full path for color overrides
    void setFullPath(const std::string &full_path){ m_full_path = full_path; }
    
protected:
    void computeBounds();
    
    typedef Imath::Vec3<unsigned int> Tri;
    typedef std::vector<Tri> TriArray;

    P3fArraySamplePtr m_meshP;
    V3fArraySamplePtr m_meshN;
    Int32ArraySamplePtr m_meshIndices;
    Int32ArraySamplePtr m_meshCounts;
    std::vector<V3f> m_customN;
    
    bool m_valid;
    bool m_isConstant;
    Box3d m_bounds;
    
    TriArray m_triangles;
    std::string m_full_path;
    
    std::vector<size_t> m_uvIndices;
    std::vector<Imath::Vec2<float>> m_uvCoords;
};

} // end ns


#endif /* MeshDrawHelper_hpp */
