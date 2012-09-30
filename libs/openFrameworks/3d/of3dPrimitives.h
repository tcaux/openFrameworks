//
//  of3dModel.h
//  openFrameworksLib
//
//  Created by Nick Hardeman on 9/14/12.
//
//
#pragma once

#include "ofMesh.h"
#include "ofRectangle.h"
#include "ofNode.h"
#include "ofTexture.h"
#include <map>

enum of3dPrimitiveType {
	OF_3D_PRIMITIVE_PLANE,
    OF_3D_PRIMITIVE_SPHERE,
    OF_3D_PRIMITIVE_ICO_SPHERE,
	OF_3D_PRIMITIVE_BOX,
	OF_3D_PRIMITIVE_CONE,
    OF_3D_PRIMITIVE_CYLINDER
};


class of3dModel : public ofNode {
public:
    of3dModel();
    virtual ~of3dModel();
    
    // applies to all the meshes evenly //
    void setTexCoords( float u1, float v1, float u2, float v2 );
    // apply to a specific mesh //
    void setTexCoords( int meshindex, float u1, float v1, float u2, float v2 );
    // does not store texture. Creates tex coords from texture, if texture is
    // non-arb, then it will create normalized tex coords //
    // defaults to index 0 
    void setTexCoordsFromTexture( ofTexture& inTexture, int tCoordsIndex=0 );
    // useful when creating a new model, since it uses normalized tex coords //
    void normalizeAndApplySavedTexCoords( int meshIndex );
    
    void addMesh( ofMesh& mesh );
    
    int getNumMeshes();
    ofMesh* getMeshPtr(int meshIndex);
    ofMesh& getMesh( int meshIndex );
    vector<ofMesh>& getMeshes();
    
    int getNumTextures();
    ofTexture* getTexturePtr(int texIndex);
    ofTexture& getTexture( int texIndex);
    map<int, ofTexture>& getTextures();
    
    int getNumTexcoords();
    ofVec4f* getTexCoordPtr( int texCoordIndex );
    ofVec4f& getTexCoord( int texCoordIndex );
    map<int, ofVec4f>& getTexCoords();
    
    bool hasScaling();
    bool hasNormalsEnabled();
    ofVec3f getResolution() const;
    
    void enableNormals();
    void enableTextures();
    
    void disableNormals();
    void disableTextures();
    
    void setResolution( int resX, int resY, int resZ );
    
    void removeMesh( int index );
    void removeTexture( int index );
    void clear();
    
    void drawVertices();
    void drawWireframe();
    void drawFaces();
    void draw();
    void draw(ofPolyRenderMode renderType);
    void drawNormals( float length );
    
protected:
    vector<ofMesh>      _meshes;
    map<int, ofVec4f>   _texCoords;
    map<int, ofTexture> _textures;
    
    ofVec3f _resolution;
};

class ofPlanePrimitive : public of3dModel {
public:
    ofPlanePrimitive();
    ofPlanePrimitive( float width, float height, int columns, int rows, ofPrimitiveMode mode=OF_PRIMITIVE_TRIANGLE_STRIP );
    ~ofPlanePrimitive();
    
    void set(float width, float height, int columns, int rows, ofPrimitiveMode mode=OF_PRIMITIVE_TRIANGLE_STRIP );
    void setDimensions( float width, float height );
    void resizeToTexture( ofTexture& inTexture );
    void setWidth( float width );
    void setHeight( float height );
    
    void setResolution( int columns, int rows );
    void setResolution(int resX, int resY, int resZ);
    
    float getWidth();
    float getHeight();
    
protected:
    float _width;
    float _height;
};

class ofSpherePrimitive : public of3dModel {
public:
    ofSpherePrimitive();
    ofSpherePrimitive( float radius, int res );
    ~ofSpherePrimitive();
    
    void set( float radius, int resolution );
    void setResolution( int res );
    void setResolution( int resX, int resY, int resZ );
    
    void setRadius(float radius);
    float getRadius();
    
protected:
    float _radius;
};

class ofIcoSpherePrimitive : public of3dModel {
public:
    ofIcoSpherePrimitive();
    ofIcoSpherePrimitive( float radius, int iterations );
    ~ofIcoSpherePrimitive();
    
    void set(float radius, int res );
    void setResolution( int iterations );
    void setResolution( int resX, int resY, int resZ );
    void setRadius(float radius);
    
    float getRadius();
    
protected:
    float _radius;
};

class ofBoxPrimitive : public of3dModel {
public:
    
protected:
    
};

class ofConePrimitive : public of3dModel {
public:
    ofConePrimitive();
    ofConePrimitive( float radius, float height, int radiusSegments, int heightSegments, int capSegments=2 );
    ~ofConePrimitive();
    
    void set( float radius, float height, int radiusSegments, int heightSegments, int capSegments=2 );
    void set( float radius, float height );
    void setResolution( int radiusSegments, int heightSegments );
    void setResolution( int resX, int resY, int resZ );
    void setRadius( float radius );
    void setHeight( float height );
    
    float getRadius();
    float getHeight();
    
protected:
    float _radius;
    float _height;
};

class ofCylinderPrimitive : public of3dModel {
public:
    ofCylinderPrimitive();
    ofCylinderPrimitive( float radius, float height, int radiusSegments, int heightSegments, int numCapSegments=2, bool bCapped = true );
    ~ofCylinderPrimitive();
    
    void set( float radius, float height, int radiusSegments, int heightSegments, int numCapSegments=2, bool bCapped=true );
    void set( float radius, float height );
    void setRadius( float radius );
    void setHeight( float height );
    void setCapped( bool bCapped );
    
    void setResolution( int radiusSegments=7, int heightSegments=3, int capSegments=2 );
    
    float getHeight();
    float getRadius();
    bool getCapped();
protected:
    float _radius;
    float _height;
    bool _bCapped;
};



ofMesh      ofGetPlaneMesh(float width, float height, int columns, int rows, ofPrimitiveMode mode=OF_PRIMITIVE_TRIANGLE_STRIP);
ofMesh      ofGetSphereMesh(float radius, int res );
ofMesh      ofGetIcosahedronMesh(float radius);
ofMesh      ofGetIcoSphereMesh(float radius, int iterations);
//ofBoxPrimitive      ofGetBox( float width, float height, float depth, int res_width, int res_height );
ofMesh      ofGetCylinderMesh( float radius, float height, int radiusSegments, int heightSegments, int numCapSegments=2, bool bCapped = true  );
ofMesh      ofGetConeMesh( float radius, float height, int radiusSegments, int heightSegments );
ofMesh      ofGetBoxMesh( float width, float height, float depth, int resX, int resY, int resZ );















