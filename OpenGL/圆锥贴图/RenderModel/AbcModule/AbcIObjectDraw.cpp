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
        else
        {
            std::cout << "暂不支持其他类型" << std::endl;
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
