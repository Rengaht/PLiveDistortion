//
//  DFlyObject.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/4.
//

#ifndef DFlyObject_h
#define DFlyObject_h
#include "ofMain.h"

class DFlyObject{
private:
    
    //==== flocking ====//
    void flock(list<shared_ptr<DFlyObject>>& others);
    void applyForce(ofVec3f force);
    ofVec3f align(list<shared_ptr<DFlyObject>>& others);
    ofVec3f cohesion(list<shared_ptr<DFlyObject>>& others);
    ofVec3f separate(list<shared_ptr<DFlyObject>>& others);
    
    //vector<ofVec3f> _vertex;
    ofVboMesh _mesh;
    ofVec3f _dest;
    
public:

    ofVec3f loc,vel,acc;
    static float rad,maxForce,maxSpeed,boundary;
    static ofVec3f cent;
    
    float phi;
    bool _shader_fill;
    
    
    //DFlyObject();
    DFlyObject(ofVec3f loc_,ofMesh mesh_,bool shader_=false);
    
    virtual void draw();
//    void drawTextureBox(ofTexture tex_);
    virtual void update();
    void updateFlock(list<shared_ptr<DFlyObject>>& others);
    
    void setDest(ofVec3f dest_);
    void updateToDest();
    
};



#endif /* DFlyObject_h */
