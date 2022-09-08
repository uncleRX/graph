//
//  AbcIObjectDraw.cpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/20.
//

#include "AbcIObjectDraw.hpp"
#include "AbcIPolyMeshDraw.hpp"
#include "Alembic/Abc/All.h"
#include "Alembic/AbcGeom/IPolyMesh.h"
#include "AbcIPolyMeshDraw.hpp"
#include <memory>


using namespace Imath;
using namespace Alembic::Abc;
using namespace AbcModule;
using namespace Alembic::AbcGeom;

AbcIObjectDraw::AbcIObjectDraw(IObject &iObj, bool iResetIfNoChildren )
: m_object( iObj )
, m_minTime( ( chrono_t )FLT_MAX )
, m_maxTime( ( chrono_t )-FLT_MAX )
{
    // If not valid, just bail.
    if ( !m_object ) { return; }
    
    // IObject has no explicit time sampling, but its children may.
    size_t numChildren = m_object.getNumChildren();
    for ( size_t i = 0; i < numChildren; ++i )
    {
        const ObjectHeader &ohead = m_object.getChildHeader( i );
        
        // 动态决定类型
        DrawablePtr dptr;
        if ( IPolyMesh::matches( ohead ) )
        {
            IPolyMesh pmesh( m_object, ohead.getName() );
            if ( pmesh)
            {
                dptr.reset( new AbcIPolyMeshDraw( pmesh ) );
            }
        }
        else if (ICamera::matches(ohead))
        {
            ICamera cameraObject(m_object, ohead.getName());
            this->parseICamera(cameraObject);
        }
        else if (IXform::matches(ohead))
        {
            IXform xFormObject(m_object, ohead.getName());
            this->parseIXform(xFormObject);
        }
        if (ISubD::matches(ohead)){}
        if (ILight::matches(ohead)){}
        if (ICurves::matches(ohead)){}
        if (IPoints::matches(ohead)){}
        if (INuPatch::matches(ohead)){}
        if (IFaceSet::matches(ohead)){}
        
        if ( dptr && dptr->valid() )
        {
            m_children.push_back( dptr );
            m_minTime = std::min( m_minTime, dptr->getMinTime() );
            m_maxTime = std::max( m_maxTime, dptr->getMaxTime() );
        }
    }
    m_bounds.makeEmpty();
    if ( m_children.size() == 0 && iResetIfNoChildren )
    {
        m_object.reset();
    }
}

void AbcIObjectDraw::parseIXform(const Alembic::AbcGeom::IXform& xform)
{
    const auto num = xform.getNumChildren();
    for(auto k = 0; k < num; k++)
    {
        const auto& header = xform.getChildHeader(k);
        DrawablePtr dptr;
        if (IPolyMesh::matches(header))
        {
            IPolyMesh mesh(xform, header.getName());
            dptr.reset(new AbcIPolyMeshDraw(mesh));
            m_children.push_back( dptr );
            // TODO: 如果有子元素应该继续解析
        }
        
        if (ICamera::matches(header))
        {
            ICamera cameraObject(xform, header.getName());
            this->parseICamera(cameraObject);
        }
        
        if (IXform::matches(header))
        {
            IXform child = IXform(xform, header.getName());
            this->parseIXform(child);
        }
    }
}

void AbcIObjectDraw::parseICamera(const ICamera& iCamera)
{
    // 如果摄像机有运动是需要更新时间的
    CameraSample cameraSample = iCamera.getSchema().getValue(
                                                             ISampleSelector(0.0));
    
    // 将垂直相机胶片还原成厘米大小
    this->verticalAperture = cameraSample.getVerticalAperture();
    // 以厘米为单位取水平相机胶片
    this->horizontalAperture = cameraSample.getHorizontalAperture();
}

void AbcIObjectDraw::readMochaMeshData(std::vector<AbcIPolyMeshData>& datas)
{
    if(this->horizontalAperture == 0 || this->verticalAperture == 0)
    {
        return;
    }
    this->readOriginalIPolyMeshDatas(datas);
    if (datas.empty())
    {
        return;
    }
    // 归一化顶点数据 , *0.1 是要转化成m, 里面的坐标是m
    float scaleX = this->horizontalAperture * 0.1;
    float scaleY = this->verticalAperture * 0.1;
    for (AbcIPolyMeshData& meshData : datas)
    {
        for (int i = 0; i < meshData.vertices.size(); i+=3)
        {
            float nvX = meshData.vertices[i];
            float nvY = meshData.vertices[i+1];
            // 坐标系归一化
            meshData.vertices[i] = nvX / scaleX;
            meshData.vertices[i+1] = nvY / scaleY;
        }
        
        for (int i = 0; i < meshData.uvs.size(); i+=2)
        {
            // uv处理
            float oldY = meshData.uvs[i + 1];
            meshData.uvs[i+1] = (1.0- oldY);
        }
    }
}

void AbcIObjectDraw::readCinema4DMeshData(std::vector<AbcIPolyMeshData>& datas)
{
    this->readOriginalIPolyMeshDatas(datas);
}

void AbcIObjectDraw::readLockDownMeshData(std::vector<AbcIPolyMeshData>& datas, float iw, float ih)
{
    float width = iw;
    float height = ih;
    
    this->readOriginalIPolyMeshDatas(datas);
    for (AbcIPolyMeshData& meshData : datas)
    {
        for (int i = 0; i < meshData.vertices.size(); i+=3)
        {
            // 坐标系归一化 , 坐标在左上角 0, 0
            float nvX = meshData.vertices[i] / width;
            float nvY = meshData.vertices[i+1] / height;
            nvX = 2.0 * nvX - 1.0;
            nvY = 1.0 - nvY * 2.0;
            
            // 转化成中间 0, 0的坐标
            meshData.vertices[i] = nvX;
            meshData.vertices[i+1] = nvY;
        }
        for (int i = 0; i < meshData.uvs.size(); i+=2)
        {
            // uv处理
            float oldY = meshData.uvs[i + 1];
            meshData.uvs[i+1] = (oldY);
        }
    }
    
}

void AbcIObjectDraw::readOriginalIPolyMeshDatas(std::vector<AbcIPolyMeshData>& datas)
{
    std::vector<AbcIPolyMeshData> results;
    for (auto subPtr : this->m_children)
    {
        AbcIPolyMeshDraw* ipolySp = dynamic_cast<AbcIPolyMeshDraw *>(subPtr.get());
        if (ipolySp)
        {
            AbcIPolyMeshData data = ipolySp->getCurrentIPolyMeshData();
            results.emplace_back(data);
        }
    }
    datas = results;
}

//-*****************************************************************************
AbcIObjectDraw::~AbcIObjectDraw()
{
    // Nothing!
}

//-*****************************************************************************
chrono_t AbcIObjectDraw::getMinTime()
{
    return m_minTime;
}

//-*****************************************************************************
chrono_t AbcIObjectDraw::getMaxTime()
{
    return m_maxTime;
}

//-*****************************************************************************
bool AbcIObjectDraw::valid()
{
    return m_object.valid();
}

//-*****************************************************************************
void AbcIObjectDraw::setTime( chrono_t iTime )
{
    if ( !m_object ) { return; }
    
    // store the current time on the drawable for easy access later
    m_currentTime = iTime;
    
    // Object itself has no properties to worry about.
    m_bounds.makeEmpty();
    for ( DrawablePtrVec::iterator iter = m_children.begin();
         iter != m_children.end(); ++iter )
    {
        DrawablePtr dptr = (*iter);
        if ( dptr )
        {
            dptr->setTime( iTime );
            // TODO: m_bounds m_bounds.extendBy( dptr->getBounds() );
        }
    }
}

//-*****************************************************************************

void AbcIObjectDraw::draw()
{
    if ( !m_object ) { return; }
    
    int i = 0;
    for ( DrawablePtrVec::iterator iter = m_children.begin();
         iter != m_children.end(); ++iter, i++ )
    {
        IObject iChild = m_object.getChild( i );
        DrawablePtr dptr = (*iter);
        if ( dptr )
        {
            dptr->draw();
        }
    }
}
