//
//  ABCScene.cpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/20.
//

#include "ABCScene.hpp"
#include "Alembic/AbcCoreFactory/All.h"
#include "AbcIObjectDraw.hpp"


using namespace AbcModule;

AbcScene::AbcScene(std::string fileName, AbcSceneParam param) :
m_fileName( fileName ),
m_minTime( ( chrono_t )FLT_MAX ),
m_maxTime( ( chrono_t )-FLT_MAX )
{
    Alembic::AbcCoreFactory::IFactory factory;
    m_archive = factory.getArchive( fileName );
    m_topObject = IObject( m_archive, kTop );
    
    m_drawable.reset( new AbcIObjectDraw( m_topObject, false ));
    ABCA_ASSERT( m_drawable->valid(),
                "Invalid drawable for archive: " << fileName );
    
    m_minTime = m_drawable->getMinTime();
    m_maxTime = m_drawable->getMaxTime();
    if ( m_minTime <= m_maxTime )
    {
        m_drawable->setTime( m_minTime );
    }
    else
    {
        m_minTime = m_maxTime = 0.0;
        m_drawable->setTime( 0.0 );
    }
    ABCA_ASSERT( m_drawable->valid(),
                "Invalid drawable after reading start time" );

//    m_bounds = m_drawable->getBounds();
}

AbcScene::~AbcScene()
{
    
}

//*****************************************************************
void AbcScene::setTime( chrono_t newTime )
{
    ABCA_ASSERT( m_archive && m_topObject &&
                m_drawable && m_drawable->valid(),
                "Invalid Scene: " << m_fileName );
    
    if ( m_minTime <= m_maxTime )
    {
        m_drawable->setTime( newTime );
        ABCA_ASSERT( m_drawable->valid(),
                    "Invalid drawable after setting time to: "
                    << newTime );
    }
    
//    m_bounds = m_drawable->getBounds();
}

//*****************************************************************
void AbcScene::draw()
{
    ABCA_ASSERT( m_archive && m_topObject &&
                m_drawable && m_drawable->valid(),
                "Invalid Scene: " << m_fileName );
    m_drawable->draw();
}
