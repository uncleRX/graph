//
//  AbcIObjectDraw.hpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/20.
//

#ifndef AbcIObjectDraw_hpp
#define AbcIObjectDraw_hpp

#include "Drawable.h"
#include "Alembic/Abc/IObject.h"
#include "Alembic/AbcGeom/IXform.h"
#include "Alembic/AbcGeom/ICamera.h"

#include "AbcIPolyMeshData.h"

namespace AbcModule
{

class AbcIObjectDraw : public Drawable
{
public:
    
    AbcIObjectDraw( Alembic::Abc::IObject &iObj, bool iResetIfNoChildren);
    virtual ~AbcIObjectDraw();
    
    virtual chrono_t getMinTime();
    virtual chrono_t getMaxTime();
    virtual bool valid();
    virtual void setTime( chrono_t iSeconds );
    virtual void draw();

    // 获取原始图元数据
    void readOriginalIPolyMeshDatas(std::vector<AbcIPolyMeshData>& datas);
    
    // 获取mocha-pro 导出的数据
    void readMochaMeshData(std::vector<AbcIPolyMeshData>& datas);
    void readLockDownMeshData(std::vector<AbcIPolyMeshData>& datas, float iw, float ih);
    void readCinema4DMeshData(std::vector<AbcIPolyMeshData>& datas);
protected:
    Alembic::Abc::IObject m_object;
    
    chrono_t m_currentTime;
    chrono_t m_minTime;
    chrono_t m_maxTime;
    
    DrawablePtrVec m_children;

    Imath::Box3d m_bounds;
    std::string m_fullName;

    float verticalAperture{0.f}; // 垂直胶片 cm
    float horizontalAperture{0.f}; // 水平胶片 cm
    
    
    void parseIXform(const Alembic::AbcGeom::IXform& xform);
    void parseICamera(const Alembic::AbcGeom::ICamera& iCamera);
};

} /* ns end */
#endif /* AbcIObjectDraw_hpp */
