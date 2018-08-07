//
//  DSandLine.h
//  PDistortionAR
//
//  Created by RengTsai on 2018/7/16.
//

#ifndef DSandLine_h
#define DSandLine_h

#define MSAND_REPEAT 5
#define MSAND_SEGMENT 8.0


class DSandLine:public DZigLine{
    
//    int _dest_length;
//    float _cur_length;
//    float _vel;
//    int _interval;
//    int _itime;
    
//    list<ofVec3f> _vertex;
    
public:
    
    DSandLine():DSandLine(ofVec3f(0),-1,list<ofVec3f>(1,ofVec3f(0))){}
    DSandLine(ofVec3f loc_,int last_,list<ofVec3f> vertex_):DZigLine(loc_,last_,vertex_){
        
        
        _wid=ofRandom(.2,.3)*rad;
        
        _mesh.clear();
        _mesh.setMode(OF_PRIMITIVE_LINES);
       
        //if(vertex_.size()>1) generateMesh(vertex_);
        //_vertex=vertex_;
        
//        _dest_length=_vertex.size();
//        _cur_length=0;
        _last_vertex=*vertex_.begin();
        
//        float time_=floor(ofRandom(80,150));
//        _vel=(float)_dest_length/(float)time_;
//
//        _interval=_last_time/time_;
//        _itime=0;
        
        //_dest_length=floor(ofRandom(100,200))*MSAND_REPEAT;
//        ofLog()<<"_dest_length= "<<_dest_length;
        //ofLog()<<"_dest_length= "<<_dest_length<<" last= "<<_last_time<<" time= "<<time_<<"  vel= "<<_vel<<" _interval= "<<_interval;
//        _shader_fill=true;
    }
    
    void expandMesh(ofVec3f dir_,ofVec3f next_){
        
        float len=next_.distance(_last_vertex);
//        ofLog()<<next_<<" -- "<<_last_vertex<<" "<<len;
        
        ofVec3f toTheLeft=dir_.getRotated(90, ofVec3f(0, 1, 1));
        ofVec3f toTheRight=dir_.getRotated(-90, ofVec3f(0, 1, 1));
        toTheLeft.normalize();
        toTheRight.normalize();
        
        
        
        //float twid_=_wid*(1-_mesh.getNumVertices()/_dest_length);
        int mseg=max(1.0,floor(len/(rad*.1)));
        for(int j=0;j<mseg;++j){
        
            //ofVec3f s_=_last_vertex+toTheLeft*ofRandom(-2,2)*_wid;
            
            ofVec3f s_=_last_vertex.interpolate(next_,(float)j/(float)mseg);
            float tlen=rad*ofRandom(.01,.2);
            _mesh.addVertex(s_);
            _mesh.addVertex(s_+dir_*tlen);
            
            
//            ofColor color_(ofRandom(100,255),ofRandom(50,255),ofRandom(50,150));
//            _mesh.addColor(color_);
//            _mesh.addColor(color_);
            
//
            _mesh.addTexCoord(ofVec2f(1,_texture_pos));
            _mesh.addTexCoord(ofVec2f(1,_texture_pos));
//            _mesh.addTexCoord(ofVec2f(_cur_length/_dest_length+.2,_texture_pos+.2));
        }
        float m=_mesh.getNumVertices();
//        ofLog()<<m;
        
        for(float i=0;i<m;i+=2){
            _mesh.setTexCoord(i,ofVec2f(i/2/m,_texture_pos));
            _mesh.setTexCoord(i+1,ofVec2f(i/2/m+_wid,_texture_pos));
        }
        
//        _last_dir=dir_;
//        _last_vertex=next_;

    }
    void addSegment(){

        ofVec3f next_=_last_dir;
        next_.rotate(ofRandom(-60,60),ofVec3f(0,1,0));
        //next_.rotate(ofRandom(-20,20),ofVec3f(0,0,1));

        next_.normalize();
        next_*=rad*ofRandom(.1,.3);

        expandMesh(next_,_last_vertex+next_);
    }

    void draw(){
        ofPushStyle();
        ofSetColor(255);
        
        
        
        ofSetLineWidth(5);
        ofDisableArbTex();
        
        ofPushMatrix();
        ofTranslate(_loc);
        //        ofRotate(90,vel.x,vel.y,vel.z);
        //        _mesh.drawWireframe();
        _mesh.draw();
        
        ofPopMatrix();
        
        ofPopStyle();
        
    }
    
//    void update(int dt_){
//        
//        DObject::update(dt_);
//        
////        _itime+=dt_;
////        if(_itime<_interval) return;
////
////        _cur_length+=_vel;
////        _itime=0;
////
////        int i_=floor(_cur_length);
////
////        if(i_<_dest_length){
////            ofVec3f next_=_vertex[i_].interpolate(_vertex[i_+1],_cur_length-i_);
////            ofVec3f dir_=_vertex[i_+1]-_vertex[i_];
////            dir_.normalize();
////
////            expandMesh(dir_,next_);
////        }else{
////            _last_time=-1;
////        }
//    }
    
    list<shared_ptr<DFlyObject>> breakdown(){
        list<shared_ptr<DFlyObject>> _fly;
        
//        int m=_mesh.getNumVertices();
//        if(m<2) return _fly;
//
//        int add_=m;//floor(ofRandom(.2,.5)*m/2);
//        int i=0;
//        while(i<add_){
//            ofMesh mesh_;
//            mesh_.setMode(OF_PRIMITIVE_LINES);
//
//            ofVec3f loc=_mesh.getVertex(i);
//
//            for(int j=0;j<2;++j){
//                mesh_.addVertex(_mesh.getVertex(i+j)-loc);
//                mesh_.addTexCoord(_mesh.getTexCoord(i+j)-loc);
//
//                //_mesh.removeVertex(j);
//            }
//
//            _fly.push_back(shared_ptr<DFlyObject>(new DFlyObject(loc,mesh_)));
//            i++;
//        }
        //_mesh.clear();
        
        return _fly;
    }
    
    
};


#endif /* DSandLine_h */
