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
    
    
protected:
    Alembic::Abc::IObject m_object;
    
    chrono_t m_currentTime;
    chrono_t m_minTime;
    chrono_t m_maxTime;
    
    DrawablePtrVec m_children;

        Imath::Box3d m_bounds;
    std::string m_fullName;
};

} /* ns end */
#endif /* AbcIObjectDraw_hpp */
