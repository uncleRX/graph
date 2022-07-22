//
//  ABCScene.hpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/20.
//

#ifndef ABCScene_hpp
#define ABCScene_hpp

#include <stdio.h>
#include "Drawable.h"
#include "Alembic/Abc/All.h"

using namespace Imath;
using namespace Alembic::Abc;



namespace AbcModule
{

struct AbcSceneParam
{
    bool isVerbose = true;
    
    //other..
};

class AbcScene
{
    
public:
    
    AbcScene(std::string fileName, AbcSceneParam param = AbcSceneParam());
    
    ~AbcScene();
    
    IArchive getArchive() { return m_archive; }
    
    IObject getTop() { return m_topObject; }
    
    chrono_t getMinTime() const { return m_minTime; }

    chrono_t getMaxTime() const { return m_maxTime; }
    
    bool isConstant() const { return m_minTime >= m_maxTime; }
    
    void setTime( chrono_t newTime );

    Box3d getBounds() const { return m_bounds; }

    void draw();

protected:
    std::string m_fileName;
    IArchive m_archive;
    IObject m_topObject;
    
    chrono_t m_minTime;
    chrono_t m_maxTime;
    Box3d m_bounds;
    
    DrawablePtr m_drawable;
};



} // end ns



#endif /* ABCScene_hpp */
