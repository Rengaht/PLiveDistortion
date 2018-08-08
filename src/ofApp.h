#pragma once

#include <ARKit/ARKit.h>
#import "AVSoundPlayer.h"


#include "ofxiOS.h"
#include "ofxARKit.h"
#include "ofxOsc.h"

#include "FrameTimer.h"
#include "DFlow.h"
#include "DFlyObject.h"
#include "DZigLine.h"
#include "DRainy.h"

#include "DPiece.h"
#include "DPieceEdge.h"


#define OSC_PORT 12345
#define MSTAGE 6
#define MPIANO 40
#define MRAIN 12
#define MAX_MFEATURE 40
#define MAX_MFLY_OBJ 40
#define MAX_MDETECT 100
#define MTOUCH_SMOOTH 6
#define BPM 40


class ofApp : public ofxiOSApp {
	
    public:
    
        ofApp (ARSession * session);
        ofApp();
        ~ofApp ();
    
        void setup();
        void update();
        void draw();
        void exit();
	
        void touchDown(ofTouchEventArgs & touch);
        void touchMoved(ofTouchEventArgs & touch);
        void touchUp(ofTouchEventArgs & touch);
        void touchDoubleTap(ofTouchEventArgs & touch);
        void touchCancelled(ofTouchEventArgs & touch);

        void lostFocus();
        void gotFocus();
        void gotMemoryWarning();
        void deviceOrientationChanged(int newOrientation);

    
        ofCamera cam;
    
        int _last_millis;
        int _dmillis;
        int _play_millis;
    
        int _ww,_wh,_projecth;
        ofTrueTypeFont _font;
    
    
    
        int _stage;
        void setStage(int set_);
    
    
        // ====== AR STUFF ======== //
        ARSession * session;
        ARRef processor;
    
        void reset();
    
        // ====== camera shader ======//
        ofShader _shader_gray;
        ofShader _shader_blur;
        ofShader _shader_canny;
        ofShader _shader_sobel;
        ofShader _shader_mapscreen;
        ofFbo _fbo_tmp1,_fbo_tmp2;
    
    
        float _sobel_threshold;
        float _shader_threshold;
    
    
        ofTexture _camera_view;
    
        void drawCameraView();
    
        //DFlow _screen_flow;
    
    
        // ====== ar object ======//
        list<shared_ptr<DObject>> _feature_object;
        shared_ptr<DObject> _record_object;
        list<shared_ptr<DFlyObject>> _fly_object;
    
        list<ofVec3f> _detect_feature;
    
    
        void updateFeaturePoint();
    
        void addARPiece(ofVec3f loc_);
        void addARParticle(ofVec3f loc_);
    
        int addFlyObject();
        void updateFlyCenter();
        void setupFlyToDest();
    
        ofMatrix4x4 _camera_projection, _camera_viewmatrix;
        ofVec3f arScreenToWorld(ofVec3f screen_pos_);
        
    
        vector<ofVec2f> _prev_touch;
        void addTouchTrajectory();
    
        FrameTimer _timer_filterIn,_timer_filterOut;
        FrameTimer _timer_bpm;
    
        // ====== ui ======//
        void resetButton();
        void nextStage();
        void prevStage();
    
    
        bool _touched;
        ofVec2f _touch_point;
    
        int _orientation;
    
        // ====== sample file ======//
        float _amp_vibe;
    
        // ====== osc ======//
        ofxOscReceiver _osc_receiver;
        void checkMessage();
    
};


