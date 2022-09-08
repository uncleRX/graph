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
#include "AbcIPolyMeshData.h"

using namespace Alembic::Abc;

namespace AbcModule
{
    struct AbcSceneParam
    {
        bool isVerbose = true;
        //other..
    };

    enum AlembicExporter
    {
        kAlembic_Exporter_MochaPro = 0, // default
        kAlembic_Exporter_Lockdown,
        kAlembic_Exporter_Cinema4D
    };

    class AbcScene
    {
    public:
 
        AbcScene(std::string fileName, AbcSceneParam param = AbcSceneParam());
        
        // 如果是 Lockdown软件倒出的数据需要使用到 宽高, 必须要设置
        void setOriginTrackSize(float w, float h);

        ~AbcScene();

        IArchive getArchive()
        { return m_archive; }

        IObject getTop()
        { return m_topObject; }

        chrono_t getMinTime() const
        { return m_minTime; }

        chrono_t getMaxTime() const
        { return m_maxTime; }

        bool isConstant() const
        { return m_minTime >= m_maxTime; }

        // 更新时间, 跟新数据时必须调用
        void setTime(chrono_t newTime);

        Box3d getBounds() const
        { return m_bounds; }

        // 获取当前可用图元的渲染数据
        void readCurrentIPolyMeshDatas(std::vector<AbcIPolyMeshData>& datas);

        // 外部暂不需要使用
        void draw();
        
    protected:
        std::string m_fileName;
        IArchive m_archive;
        IObject m_topObject;

        chrono_t m_minTime;
        chrono_t m_maxTime;
        Box3d m_bounds;

        DrawablePtr m_drawable;
        AlembicExporter m_exporter;
        
    private:
        
        float originWidth = 0;
        float originHeight = 0;
        // 更新导出的平台
        void updateExporter(std::string name);
    };
} // end ns



#endif /* ABCScene_hpp */
