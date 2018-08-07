#include "ofApp.h"

//--------------------------------------------------------------
ofApp :: ofApp (ARSession * session){
    this->session = session;
    cout << "creating ofApp" << endl;
}

ofApp::ofApp(){}

//--------------------------------------------------------------
ofApp :: ~ofApp () {
    cout << "destroying ofApp" << endl;
}

//--------------------------------------------------------------
void ofApp::setup(){
    
    ofBackground(0);
//    ofSetOrientation(OF_ORIENTATION_90_LEFT);
    
    _stage=-1;
    
    /* init osc */
    cout<<"listening for osc messages on port "<<OSC_PORT<<"\n";
    _osc_receiver.setup(OSC_PORT);
    
    int fontSize = 8;
    if (ofxiOSGetOFWindow()->isRetinaSupportedOnDevice())
        fontSize *= 2;
    _font.load("fonts/mono0755.ttf", fontSize);
    
    ofxAccelerometer.setup();
    
    processor = ARProcessor::create(session);
    processor->setup(true);
    
    
   
    
    if(ofGetWindowWidth()>ofGetWindowHeight()){
        _ww=ofGetHeight();
        _wh=ofGetWidth();
    }else{
        _ww=ofGetWidth();
        _wh=ofGetHeight();
    }
    
    
    _fbo_tmp1.allocate(_ww,_wh,GL_RGB);
    _fbo_tmp2.allocate(_ww,_wh,GL_RGB);
    
   
    
    _shader_gray.load("shaders/grayScale.vert", "shaders/grayScale.frag");
    _shader_blur.load("shaders/blur.vert", "shaders/blur.frag");
    _shader_blur.begin();
    _shader_blur.setUniform1f("window_width", _ww);
    _shader_blur.setUniform1f("window_height", _wh);
    _shader_blur.end();
    
    _shader_canny.load("shaders/canny.vert", "shaders/canny.frag");
    _shader_sobel.load("shaders/sobel.vert", "shaders/sobel.frag");
    _shader_sobel.begin();
    _shader_sobel.setUniform1f("window_width", _ww);
    _shader_sobel.setUniform1f("window_height", _wh);
    _shader_sobel.end();
    
    _shader_mapscreen.load("shaders/mapScreen.vert", "shaders/mapScreen.frag");
    _shader_mapscreen.begin();
    _shader_mapscreen.setUniform1f("window_width", _ww*10.0);
    _shader_mapscreen.setUniform1f("window_height", _wh*2.0);
    _shader_mapscreen.end();
    
    float s=_ww/10000.0;
    DFlyObject::maxForce=.2*s;
    DFlyObject::maxSpeed=8*s;
    DFlyObject::rad=1.0*s;
    DFlyObject::cent=ofVec3f(0,0,0);
    
    
    _touched=false;
    
    _last_millis=ofGetElapsedTimeMillis();
    _dmillis=0;
    
    _shader_threshold=0;
    _sobel_threshold=.5;
    
    //_screen_flow=DFlow(_shader_threshold);
    
    _timer_filterIn=FrameTimer(800);
    _timer_filterOut=FrameTimer(500);
    _timer_bpm=FrameTimer((float)60000/(float)BPM);
    _timer_bpm.restart();
    
    
    reset();
    

}

//--------------------------------------------------------------
void ofApp::update(){
    
    checkMessage();
    ofSetBackgroundColor(255);
    processor->update();
    
    
    _dmillis=ofGetElapsedTimeMillis()-_last_millis;
    _last_millis+=_dmillis;
    
    _timer_bpm.update(_dmillis);
    
    //// update camera ////
    auto cam_matrix=processor->getCameraMatrices();
    ofMatrix4x4 model = ARCommon::toMat4(session.currentFrame.camera.transform);
    _camera_projection=cam_matrix.cameraProjection;
    _camera_viewmatrix=model*cam_matrix.cameraView;
    _camera_view=processor->camera->getCameraImage();
    

    
    switch(_stage){
        case 0:
            _sobel_threshold=0;
            _shader_threshold=0;
            break;
        case 1:
            _timer_filterIn.update(_dmillis);
            _sobel_threshold=.2;
            _shader_threshold=_timer_filterIn.val();
            if(_shader_threshold>=1.0){
                if(_timer_bpm.val()==1) updateFeaturePoint();
            }
            return;
        case 2:
            _shader_threshold=1.0;
            _sobel_threshold=.5;
            if(_timer_bpm.val()==1){
                if(_detect_feature.size()>0){
                    addARPiece(_detect_feature.front());
                    _detect_feature.pop_front();
                }
                updateFeaturePoint();
            }
            break;
        case 3:
            _sobel_threshold=.5;
            _shader_threshold=1.0;
            if(_touched){
                addTouchTrajectory();
            }
            break;
        case 4:
            _shader_threshold=1+abs(.5*sin(ofGetFrameNum()/30.0*TWO_PI+ofRandom(-2,2)));
            _sobel_threshold=.5;
            
            if(ofRandom(5)<1) addFlyObject();
            
            updateFlyCenter();
            for(auto& p:_fly_object){
                p->updateFlock(_fly_object);
            }
            break;
        case 5:
             _shader_threshold=1-_timer_filterOut.val();
            _timer_filterOut.update(_dmillis);
            for(auto& p:_fly_object){
                p->updateToDest();
            }
            break;
    }
    
   
  
    if(_record_object) _record_object->update(_dmillis);

    for(auto& it:_feature_object) it->update(_dmillis);
    _feature_object.remove_if([](shared_ptr<DObject> obj){return obj->dead();});
    
    int m=_feature_object.size()-MAX_MFEATURE;
    if(m>0){
        for(int i=0;i<m;++i){
          _feature_object.pop_front();
        }
    }
    
    if(_timer_bpm.val()==1) _timer_bpm.restart();
    
    
}

void ofApp::updateFeaturePoint(){
    
    auto pts_=processor->pointCloud.getPoints(this->session.currentFrame);
    if(pts_.size()>1){
        pts_.resize(MAX_MDETECT/10);
        //random_shuffle(pts_.begin(), pts_.end());
        _detect_feature.insert(_detect_feature.begin(),pts_.begin(),pts_.end());
        if(_detect_feature.size()>MAX_MDETECT) _detect_feature.resize(MAX_MDETECT);
    }
}

void ofApp::addARPiece(ofVec3f loc_){
    int last=-1;//ofRandom(2)<1?-1:floor(ofRandom(2000,1000));
    _feature_object.push_back(shared_ptr<DObject>(new DPiece(loc_,last)));
    if(ofRandom(3)<1){
        int m=floor(ofRandom(1,4));
        for(int i=0;i<m;++i){
        ofVec3f offset_(ofRandom(-1,1));
        offset_*=DObject::rad/10;
        _feature_object.push_back(shared_ptr<DObject>(new DPieceEdge(loc_+offset_,last)));
        }
    }
    //random_shuffle(_feature_object.begin(), _feature_object.end());

}


void ofApp::addARParticle(ofVec3f loc_){
    
    _feature_object.push_back(shared_ptr<DObject>(new DRainy(loc_,floor(ofRandom(2000,10000)))));
    //random_shuffle(_feature_object.begin(), _feature_object.end());

}

int ofApp::addFlyObject(){
    
    
    list<shared_ptr<DFlyObject>> pt;
    
    if(_record_object){
        pt=_record_object->breakdown();
    }
    if(pt.size()<1){
        _record_object.reset();
        
        if(_feature_object.size()>1){
            auto it=_feature_object.begin();
            pt=(*it)->breakdown();
            _feature_object.pop_front();
        }
    };
        
    _fly_object.insert(_fly_object.end(),pt.begin(),pt.end());
        
    ofLog()<<"break down to "<<pt.size()<<" flyobjects!";
    
    
    if(_fly_object.size()>MAX_MFLY_OBJ) _fly_object.resize(MAX_MFLY_OBJ);
    return pt.size();
    
}

ofVec3f ofApp::arScreenToWorld(ofVec3f screen_pos){
    
    ofVec4f pos = ARCommon::screenToWorld(screen_pos,_camera_projection,_camera_viewmatrix);
    
    // build matrix for the anchor
    matrix_float4x4 translation = matrix_identity_float4x4;
    
    translation.columns[3].x = pos.x;
    translation.columns[3].y = pos.y;
    translation.columns[3].z = screen_pos.z;
    matrix_float4x4 transform = matrix_multiply(session.currentFrame.camera.transform,translation);
    return ARCommon::toMat4(transform).getTranslation();
    
}
void ofApp::updateFlyCenter(){
    
    float flyz_=-1+_timer_bpm.val()*2;
    ofVec3f center_=arScreenToWorld(ofVec3f(_ww/2,_wh/2,flyz_));
    ofVec3f camera_pos=processor->getCameraPosition();
    
    
    ofVec3f dir_=center_-camera_pos;
    dir_.rotate(90*sin(ofGetFrameNum()/50.0), ofVec3f(0,0,1));
    
    ofVec3f vel_=(camera_pos+dir_)-DFlyObject::cent;
    vel_.normalize();
    vel_*=DFlyObject::maxForce/2.0;
    
    DFlyObject::cent+=vel_;
    
}
void ofApp::setupFlyToDest(){
    
    while(addFlyObject()>0){}
        
//    ofVec3f camera_pos=processor->getCameraPosition();
    
    for(auto& fly:_fly_object){
        ofVec3f dest_=arScreenToWorld(ofVec3f(ofRandom(_ww),ofRandom(_wh),-1));
//        ofVec3f dest_=camera_pos+ofVec3f(ofRandom(-.1,.1));
        fly->setDest(dest_);
    }
}

void ofApp::addTouchTrajectory(){
    
    if(_touched){
        
        _prev_touch.push_back(_touch_point);
        
        if(_prev_touch.size()<MTOUCH_SMOOTH) return;
        
        ofVec2f average_(0);//_prev_touch[MTOUCH_SMOOTH-1];
        float m=MTOUCH_SMOOTH;
        for(int i=0;i<m;++i){
            average_+=_prev_touch[i]/m;
        }
        
        ofVec3f pos=arScreenToWorld(ofVec3f(average_.x,average_.y,-1));
        _record_object->setAmp(_amp_vibe);
        _record_object->addSegment(pos);
        
        if(_prev_touch.size()>m) _prev_touch.erase(_prev_touch.begin());
    }
    
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofEnableAlphaBlending();
    
    ofDisableDepthTest();
    drawCameraView();
    
    ofEnableDepthTest();
    

    cam.begin();
    processor->setARCameraMatrices();
    
    

    _camera_view.bind();
    _shader_mapscreen.begin();
    _shader_mapscreen.setUniformTexture("inputImageTexture", _camera_view, 0);
    _shader_mapscreen.setUniform1f("window_width", ofGetWidth()*10.0);
    _shader_mapscreen.setUniform1f("window_height", ofGetHeight()*2.0);
    _shader_mapscreen.setUniform1f("frame_count", ((float)ofGetFrameNum()/150.0));

    for(auto& p:_feature_object)
        if(p->_shader_fill) p->draw();
    for(auto& p:_fly_object)
        if(p->_shader_fill) p->draw();
    
    _shader_mapscreen.end();

    _camera_view.bind();
    for(auto& p:_feature_object)
        if(!p->_shader_fill) p->draw();
    for(auto& p:_fly_object)
        if(!p->_shader_fill) p->draw();
    
    if(_record_object) _record_object->draw();
    
    
    _camera_view.unbind();


    
        ofPushStyle();
        float a_=ofClamp(ofMap(_amp_vibe,.7,1,0,1),.1,1);
        float t_=ofGetFrameNum()/(80-40.0*a_);
        //ofLog()<<a_;

        ofVec3f p2;
        for(auto it=_detect_feature.begin();it!=_detect_feature.end();++it){
            auto p=*it;
            //ofSetColor(255,255,0,a_*(150+100*sin((t_+p.x*50)*TWO_PI)));
            ofSetColor(255, 255, 0);
            ofDrawSphere(p.x,p.y,p.z,0.001);

//            if(a_>.8 && ofRandom(20)<1){
//                if(p.distance(p2)<=DObject::rad/2) ofDrawLine(p2.x,p2.y,p2.z,p.x,p.y,p.z);
//            }
            p2=p;
        }
        ofPopStyle();
    
   
    
    
    cam.end();
    
    
    ofDisableDepthTest();
    
    ofPushMatrix();
    ofTranslate(_ww/2,_wh/2);
    ofRotateZ(90);
    ofTranslate(-_wh/2,-_ww/2);
    ofDrawAxis(20);
    
    float p=20;
    float x=p;
    float y=p;
    _font.drawString(ofToString( ofGetFrameRate() ),x,y+=p);
    _font.drawString("stage= " + ofToString(_stage),x, y+=p);
    //_font.drawString("mfeature= " + ofToString(_feature_mesh.getNumVertices()),x, y+=p);
    _font.drawString("mfeature= " + ofToString(_detect_feature.size()),x, y+=p);
    _font.drawString("amp= " + ofToString(_amp_vibe),x, y+=p);
    
    if(processor->camera->getTrackingState()!=2) _font.drawString("!bad tracking state!",x, y+=p);
    
    ofPushStyle();
    ofSetColor(255,0,0);
    float b_=_timer_bpm.val();
    //if(b_<0.8) b_=.2;
    ofDrawCircle(x+p/2, y+=p,b_*p);
    ofPopStyle();
    
    ofPopMatrix();
    
    
}

//--------------------------------------------------------------
void ofApp::exit(){
    
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    
    _touched=true;
    _touch_point.x=touch.x;
    _touch_point.y=touch.y;
    
   
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
        _touch_point.x=touch.x;
        _touch_point.y=touch.y;
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
    _touched=false;
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){
    //ofxiOSGetOFWindow()->setOrientation(OF_ORIENTATION_DEFAULT);
//    _orientation=newOrientation;
    
    _ww=ofGetWidth();
    _wh=ofGetHeight();
}


void ofApp::drawCameraView(){
    
    
//    ofPushMatrix();
//    ofTranslate(_ww/2, _wh/2);
//    if(_orientation==3||_orientation==4) ofRotate(90);
//    ofTranslate(-_ww/2, -_wh/2);
    
    

    if(_shader_threshold<=0){
        processor->draw();

    }else{

       
       
        _fbo_tmp1.begin();
        _shader_gray.begin();
        _shader_gray.setUniformTexture("inputImageTexture", _camera_view, 0);
        _camera_view.draw(0, 0, _ww, _wh);
        _shader_gray.end();
        _fbo_tmp1.end();

        _fbo_tmp2.begin();
        _shader_blur.begin();
        _shader_blur.setUniformTexture("inputImageTexture", _fbo_tmp1.getTexture(), 0);
        _fbo_tmp1.draw(0, 0, _ww, _wh);
        _shader_blur.end();
        _fbo_tmp2.end();



        _fbo_tmp1.begin();
        _shader_sobel.begin();
        
        _shader_sobel.setUniformTexture("inputImageTexture", _fbo_tmp2.getTexture(), 0);
        _shader_sobel.setUniform1f("window_width", _ww);
        _shader_sobel.setUniform1f("window_height", _wh);
        _shader_sobel.setUniform1f("show_threshold", _shader_threshold);
        _shader_sobel.setUniform1f("sobel_threshold", _sobel_threshold);
//        if(_shader_threshold<1.0) _shader_sobel.setUniformMatrix4f("particlePos", _screen_flow.getParticleMat());
        

        _camera_view.draw(0, 0, _ww,_wh);
        //window_.draw();

        _shader_sobel.end();
        _fbo_tmp1.end();

        _fbo_tmp1.draw(0,0,_ww,_wh);
        

    
    }
//
//    ofPopMatrix();
    
}

void ofApp::reset(){
    ofLog()<<"reset scene!";
    
    if(processor->anchorController!=nil){
        
        processor->anchorController->clearAnchors();
        processor->restartSession();
    }
    //processor->anchorController->clearPlaneAnchors();
    
    //processor->restartSession();
    //[session runWithConfiguration:session.configuration options:ARSessionRunOptionResetTracking|ARSessionRunOptionRemoveExistingAnchors];
    
    _detect_feature.clear();
    _feature_object.clear();
    _fly_object.clear();
//    _static_object.clear();
//    _record_object.clear();
    
    setStage(0);

    
    _amp_vibe=0;
    
}

// ======================== BUTTON ======================== //
void ofApp::resetButton(){
  
    _feature_object.clear();
    if(_stage!=1) setStage(1);
    ofVec3f pos=arScreenToWorld(ofVec3f(ofGetWidth()/2,ofGetHeight()/2,-1));
    addARPiece(pos);
    
}



void ofApp::nextStage(){
    
    setStage(_stage+1);
}
void ofApp::prevStage(){
    
    if(_stage==1) reset();
    else setStage(_stage-1);
    
}
void ofApp::setStage(int set_){
    
    if(set_>=MSTAGE|| set_<0) return;
    _stage=set_;
    
    float s=_ww/10000.0;
    DZigLine* rec_;
    switch(_stage){
        case 0:
            _detect_feature.clear();
            _feature_object.clear();
            _fly_object.clear();
            _shader_threshold=0;
            break;
        case 1:
            
            
            _fly_object.clear();
            _detect_feature.clear();
            _feature_object.clear();
            
            _timer_filterIn.restart();
            break;
        case 2:
            _fly_object.clear();
            
            _timer_bpm.restart();
            break;
        case 3:
            _fly_object.clear();
            
            rec_=new DZigLine();
            _record_object=shared_ptr<DObject>(rec_);
            break;
        case 4:
            _detect_feature.clear();
            DFlyObject::maxForce=.2*s;
            DFlyObject::maxSpeed=5*s;
            break;
        case 5:
            setupFlyToDest();
            
            _detect_feature.clear();
            _feature_object.clear();
            
            DFlyObject::maxForce=.07*s;
            DFlyObject::maxSpeed=3*s;
            _timer_filterOut.restart();
            break;
    }

}

void ofApp::checkMessage(){
    
    while(_osc_receiver.hasWaitingMessages()){
        
        ofxOscMessage m;
        _osc_receiver.getNextMessage(m);
        
        string address_=m.getAddress();
        //ofLog()<<"get message: "<<address_;
        
        if(address_=="/amp"){
            _amp_vibe=m.getArgAsFloat(0);
            //ofLog()<<"get amp= "<<_amp_vibe;
        }else if(address_=="/stage"){
            setStage(m.getArgAsInt32(0));
        }else if(address_=="/cue"){
            switch(_stage){
                case 0:
                    break;
                case 2:
                    if(_feature_object.size()>0){
                        addARParticle(_detect_feature.front());
                        _detect_feature.pop_front();
                    }
                    break;
            }
        }else if(address_=="/next"){
            nextStage();
        }else if(address_=="/prev"){
            prevStage();
        }else if(address_=="/setbpm"){
            if(m.getNumArgs()>0) _timer_bpm=FrameTimer(m.getArgAsInt32(0));
            _timer_bpm.restart();
        }
        
    }
    
}
