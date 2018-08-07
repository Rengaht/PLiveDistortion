//
//  FrameTimer.h
//  PDistortionLive
//
//  Created by RengTsai on 2018/8/6.
//

#ifndef FrameTimer_h
#define FrameTimer_h

class FrameTimer{
public:
    
    
    FrameTimer(){
        setup(0,0);
    }
    FrameTimer(float len_){
        setup(len_,0);
    }
    FrameTimer(float len_,float delay_){
        setup(len_,delay_);
    }
    void start(){
        started=true;
    }
    void stop(){
        started=false;
    }
    void reset(){
        started=false;
        ani_t=-delay;
        event_raised=false;
        num_cycle=0;
    }
    void update(float dt_){
        if(!started) return;
        if(ani_t<due) ani_t+=dt_;
        if(ani_t>=due){
            
            if(!continuous && event_raised) return;
            
            event_raised=true;
            num_cycle++;
            
            int data=num_cycle;
    //        ofNotifyEvent(finish_event,data);
            
            if(continuous) ani_t=0;
            
        }
    }
    float val(){
        //if(!started) return 0;
        if(ani_t<0) return 0;
        if(ani_t>=due) return 1;
        
        return ofClamp(ani_t/due,0,1);
    }
    float eval(){
        float v=val();
        return v*v;
    }
    void restart(){
        reset();
        start();
    }
    
    float valEase(){
        float p=val();
        return sin(p *HALF_PI);
    }
    float valFade(){
        float d_=.05;
        float p=val();
        if(p<d_){
            return sin(p/d_*HALF_PI);
        }else if(p>1.0-d_){
            return 1.0-sin((p-(1.0-d_))/d_*HALF_PI);
        }else{
            return 1;
        }
    }
    bool isStart(){
        return started;
    }
    
    
private:
    float ani_t;
    float due,delay;
    bool started;
    bool event_raised;
    //bool loop;
    int num_cycle;
    bool continuous;
    
    void setup(float len_,float delay_){
        due=len_;
        delay=delay_;
        continuous=false;
        reset();
    }
    
    
};
#endif /* FrameTimer_h */
