//
//  IPolyMeshDraw.cpp
//  RenderModel
//
//  Created by 任迅 on 2022/7/20.
//

#include "AbcIPolyMeshDraw.hpp"
#include "Alembic/AbcGeom/All.h"
#include "Alembic/Abc/ICompoundProperty.h"

using namespace AbcModule;
using namespace Alembic::AbcGeom;
using namespace Alembic::Abc;

AbcIPolyMeshDraw::AbcIPolyMeshDraw(IPolyMesh &iPmesh) : AbcIObjectDraw( iPmesh, false), m_polyMesh( iPmesh )
{
    // Get out if problems.
    if ( !m_polyMesh.valid() )
    {
        return;
    }
    
    // set constancy on the mesh draw helper
    m_drwHelper.setConstant( m_polyMesh.getSchema().isConstant() );
    
    if ( m_polyMesh.getSchema().getNumSamples() > 0 )
    {
        m_polyMesh.getSchema().get( m_samp );
    }
    
    m_boundsProp = m_polyMesh.getSchema().getSelfBoundsProperty();
    
    // The object has already set up the min time and max time of
    // all the children.
    // if we have a non-constant time sampling, we should get times
    // out of it.
    TimeSamplingPtr iTsmp = m_polyMesh.getSchema().getTimeSampling();
    if ( !m_polyMesh.getSchema().isConstant() )
    {
        size_t numSamps =  m_polyMesh.getSchema().getNumSamples();
        if ( numSamps > 0 )
        {
            chrono_t minTime = iTsmp->getSampleTime( 0 );
            m_minTime = std::min( m_minTime, minTime );
            chrono_t maxTime = iTsmp->getSampleTime( numSamps-1 );
            m_maxTime = std::max( m_maxTime, maxTime );
        }
    }
    
    m_fullName=m_polyMesh.getFullName();
}

AbcIPolyMeshDraw::~AbcIPolyMeshDraw()
{
    // Nothing!
}

bool AbcIPolyMeshDraw::valid()
{
    return AbcIObjectDraw::valid() && m_polyMesh.valid();
    
}

void AbcIPolyMeshDraw::setTime( chrono_t iSeconds)
{
    AbcIObjectDraw::setTime( iSeconds );
    if ( !valid() )
    {
        m_drwHelper.makeInvalid();
        return;
    }
    
    // Use nearest for now.
    ISampleSelector ss( iSeconds, ISampleSelector::kNearIndex );
    IPolyMeshSchema::Sample psamp;
    
    if ( m_polyMesh.getSchema().isConstant() )
    {
        psamp = m_samp;
    }
    else if ( m_polyMesh.getSchema().getNumSamples() > 0 )
    {
        m_polyMesh.getSchema().get( psamp, ss );
    }
    
    ///////////////////////////////////////////////////////////////
    // UVs.
    ///////////////////////////////////////////////////////////////
    std::vector<size_t> uv_idxs;  // UV indices.
    std::vector<Imath::Vec2<float>> uv_coords;  // UV indices.
    IV2fGeomParam uv_param = m_polyMesh.getSchema().getUVsParam();
    ISampleSelector uss(iSeconds, ISampleSelector::kNearIndex);
    
    if (uv_param.valid())
    {
        auto uv_sample = uv_param.getIndexedValue(uss);
        if (uv_sample.valid())
        {
            // Retrieve UV indices.
            const auto abc_uv_idxs = uv_sample.getIndices()->get();
            const auto uv_idxs_count = uv_sample.getIndices()->size();
            
            uv_idxs.reserve(uv_idxs_count);
            
            for (auto i = 0; i < uv_idxs_count; i++)
            {
                uv_idxs.push_back(abc_uv_idxs[i]);
            }
            
            // UV vectors.
            const auto uvs = uv_sample.getVals()->get();
            const auto uv_count = uv_sample.getVals()->size();
            
            for (auto i = 0; i < uv_count; ++i)
            {
                auto value = uvs[i];
                uv_coords.push_back(value);
            
            }
        }
    }
    
    // Get the stuff.
    P3fArraySamplePtr P = psamp.getPositions();
    Int32ArraySamplePtr indices = psamp.getFaceIndices();
    Int32ArraySamplePtr counts = psamp.getFaceCounts();
    
    Box3d bounds;
    bounds.makeEmpty();
    
    if ( m_boundsProp && m_boundsProp.getNumSamples() > 0 )
    {
        bounds = m_boundsProp.getValue( ss );
    }
    // Update the mesh hoo-ha.
    m_drwHelper.update( P, V3fArraySamplePtr(),
                       indices, counts, uv_idxs,uv_coords, bounds );
    
    // TODO: bounds

}

void AbcIPolyMeshDraw::draw()
{
    if ( !valid() )
    {
        return;
    }
    m_drwHelper.setFullPath(m_fullName);
    m_drwHelper.draw();
//    // TODO: bounds
//    AbcIObjectDraw::draw();
}
