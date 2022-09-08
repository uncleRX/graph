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

/// 通过内参构造投影矩阵
/// @param w 视口宽
/// @param h 视口高
/// @param fx 水平焦距
/// @param fy 垂直焦距
/// @param cx 水平方向中心点
/// @param cy 垂直方向中心点
/// @param znear 近平面
/// @param zfar 远平面
void InitProjectMat(float w, float h, float fx, float fy, float cx, float cy, float znear, float zfar, float proj[16])
{
    proj[0] = 2 * fx / w;
    proj[1] = 0.0f;
    proj[2] = 0.0f;
    proj[3] = 0.0f;
    
    proj[4] = 0.0f;
    proj[5] = 2 * fy / h;
    proj[6] = 0.0f;
    proj[7] = 0.0f;
    
    proj[8] = (w - 2.f * cx) / w;
    proj[9] = (h - 2.f * cy) / h;
    proj[10] = (-zfar - znear) / (zfar - znear);
    proj[11] = -1.0f;
    
    proj[12] = 0.0f;
    proj[13] = 0.0f;
    proj[14] = -2.0f * zfar * znear / (zfar - znear);
    proj[15] = 0.0f;
}

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
        }else if ( IPoints::matches( ohead ) )
        {
            IPoints points( m_object, ohead.getName() );
            if ( points )
            {
//                dptr.reset( new IPointsDrw( points ) );
            }
        }
        else if ( ICurves::matches( ohead ) )
        {
            ICurves curves( m_object, ohead.getName() );
            if ( curves )
            {
//                dptr.reset( new ICurvesDrw( curves ) );
            }
        }
        else if ( INuPatch::matches( ohead ) )
        {
            INuPatch nuPatch( m_object, ohead.getName() );
            if ( nuPatch )
            {
//                dptr.reset( new INuPatchDrw( nuPatch ) );
            }
        }
        else if ( IXform::matches( ohead ) )
        {
            IXform xform( m_object, ohead.getName() );
            if ( xform )
            {
//                dptr.reset( new IXformDrw( xform ) );
            }
        }
        else if ( ISubD::matches( ohead ) )
        {
            ISubD subd( m_object, ohead.getName() );
            if ( subd )
            {
//                dptr.reset( new ISubDDrw( subd ) );
            }
        }else if (ICamera::matches(ohead))
        {
            ICamera cameraObject(m_object, ohead.getName());
            // 采样值是否会发生变化
            bool isConstant = cameraObject.getSchema().isConstant();
            
            auto cameraSchema = cameraObject.getSchema();
            
            CameraSample cameraSample = cameraObject.getSchema().getValue(
                                        ISampleSelector(0.0));
            
            
            int samples = cameraObject.getSchema().getNumSamples();
            
            auto focalLength = cameraSample.getFocalLength();
            auto nearClippingPlane = cameraSample.getNearClippingPlane();
            auto farClippingPlane = cameraSample.getFarClippingPlane();
            
            // 相机到被聚焦物体的距离
            auto focusDistance = cameraSample.getFocusDistance();
            
            // 将垂直相机胶片还原成厘米大小
            auto fx = cameraSample.getVerticalAperture();
            // 以厘米为单位取水平相机胶片
            auto fy = cameraSample.getHorizontalAperture();
            
            // 得到水平胶片背面偏移，单位为厘米
            auto fyo = cameraSample.getHorizontalFilmOffset();
            
            auto matrix = cameraSample.getFilmBackMatrix();
            
            // !获取相机镜头水平压缩图像的量
            // !(宽高纵横比) 未压缩 就是1.0
            auto ratio = cameraSample.getLensSqueezeRatio();
            // 获得光圈
            auto fStop = cameraSample.getFStop();
            
            int ops = cameraSample.getNumOps();
            int opsc = cameraSample.getNumOpChannels();

            
            
            double top, bottom, left, right;
            cameraSample.getScreenWindow(top, bottom, left, right);

            double winx = cameraSample.getHorizontalFilmOffset() *
                    cameraSample.getLensSqueezeRatio() /
                            cameraSample.getHorizontalAperture();

            double winy = cameraSample.getVerticalFilmOffset() *
                    cameraSample.getLensSqueezeRatio() /
                            cameraSample.getVerticalAperture();
            
            auto bounds = cameraSample.getChildBounds();

            
            std::cout << "ICamera" << std::endl;
             
//            InitProjectMat(1280, 720, fx * 10, fx * 10, <#float cx#>, <#float cy#>, nearClippingPlane, farClippingPlane, float *proj)
    
        }
        else
        {
            std::cout << "暂不支持其他类型:" << ohead.getName() << std::endl;

        }

        if ( dptr && dptr->valid() )
        {
            m_children.push_back( dptr );
            m_minTime = std::min( m_minTime, dptr->getMinTime() );
            m_maxTime = std::max( m_maxTime, dptr->getMaxTime() );
        }
    }

    // Make the bounds empty to start
    m_bounds.makeEmpty();

    // If we have no children, just leave.
    if ( m_children.size() == 0 && iResetIfNoChildren )
    {
        m_object.reset();
    }
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
