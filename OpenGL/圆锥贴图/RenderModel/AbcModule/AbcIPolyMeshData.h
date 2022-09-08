//
// Created by 任迅 on 2022/7/27.
//

#ifndef ZHUQUE_LAB_ABCIPOLYMESHDATA_H
#define ZHUQUE_LAB_ABCIPOLYMESHDATA_H


namespace AbcModule
{
    struct AbcIPolyMeshData
    {
        // 多个图元时用于区分是哪个图元
        std::string name = "";

        // current Frame
        int32_t frame = 0;

        // abc场景中当前时间
        float seconds = 0.0f;

        // 顶点数据
        std::vector<float> vertices {};
        int32_t vertexCount = 0;

        // uv坐标
        std::vector<float> uvs {};
        int32_t uvsCount = 0;
    };
}


#endif //ZHUQUE_LAB_ABCIPOLYMESHDATA_H
