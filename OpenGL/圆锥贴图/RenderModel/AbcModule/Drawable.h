//
//  Drawable.h
//  RenderModel
//
//  Created by 任迅 on 2022/7/20.
//

#ifndef Drawable_h
#define Drawable_h

#include "Alembic/Util/All.h"
#include "Alembic/AbcCoreAbstract/All.h"
#include "Imath/ImathBox.h"

using Alembic::AbcCoreAbstract::chrono_t;
using Alembic::AbcCoreAbstract::index_t;

namespace AbcModule
{

class Drawable : private Alembic::Util::noncopyable
{
public:
    Drawable() {}

    virtual ~Drawable() {}

    virtual chrono_t getMinTime() = 0;

    virtual chrono_t getMaxTime() = 0;

    virtual bool valid() = 0;

    virtual void setTime( chrono_t iSeconds ) = 0;
    
    virtual void draw() = 0;
    
};
typedef Alembic::Util::shared_ptr<Drawable> DrawablePtr;
typedef std::vector<DrawablePtr> DrawablePtrVec;

}

#endif /* Drawable_h */
