//
//  IPolyMeshDraw.hpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/20.
//

#ifndef IPolyMeshDraw_hpp
#define IPolyMeshDraw_hpp

#include <stdio.h>
#include "AbcIObjectDraw.hpp"
#include "AbcMeshDrawHelper.hpp"
#include "Alembic/AbcGeom/IPolyMesh.h"
#include "Alembic/Abc/All.h"

using namespace Alembic::AbcGeom;

namespace AbcModule
{

class AbcIPolyMeshDraw : public AbcIObjectDraw
{
    
public:
    
    AbcIPolyMeshDraw( IPolyMesh &iPmesh );

    virtual ~AbcIPolyMeshDraw();

    virtual bool valid();

    virtual void setTime( chrono_t iSeconds );

    virtual void draw();

    // 获取当前可用图元的渲染数据
    AbcIPolyMeshData getCurrentIPolyMeshData();

protected:

    IPolyMesh m_polyMesh;
    IPolyMeshSchema::Sample m_samp;
    IPolyMeshSchema::Sample m_uvSamp;
    IBox3dProperty m_boundsProp;
    MeshDrawHelper m_drwHelper;
};

}

#endif /* IPolyMeshDraw_hpp */
