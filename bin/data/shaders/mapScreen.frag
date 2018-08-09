precision highp float;

//uniform sampler2D Sampler;
uniform sampler2D inputImageTexture;
//uniform mat4 particlePos;
uniform float window_width;
uniform float window_height;
uniform float frame_count;
uniform int draw_pattern;

varying vec2 texCoord;
//varying vec4 vertexColor;

//float sum;
//float dr;
//float dx;
//float dy;
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec2 fade(vec2 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

float cnoise(vec2 P){
    vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
    vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
    Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation
    vec4 ix = Pi.xzxz;
    vec4 iy = Pi.yyww;
    vec4 fx = Pf.xzxz;
    vec4 fy = Pf.yyww;
    vec4 i = permute(permute(ix) + iy);
    vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
    vec4 gy = abs(gx) - 0.5;
    vec4 tx = floor(gx + 0.5);
    gx = gx - tx;
    vec2 g00 = vec2(gx.x,gy.x);
    vec2 g10 = vec2(gx.y,gy.y);
    vec2 g01 = vec2(gx.z,gy.z);
    vec2 g11 = vec2(gx.w,gy.w);
    vec4 norm = 1.79284291400159 - 0.85373472095314 *
    vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
    g00 *= norm.x;
    g01 *= norm.y;
    g10 *= norm.z;
    g11 *= norm.w;
    float n00 = dot(g00, vec2(fx.x, fy.x));
    float n10 = dot(g10, vec2(fx.y, fy.y));
    float n01 = dot(g01, vec2(fx.z, fy.z));
    float n11 = dot(g11, vec2(fx.w, fy.w));
    vec2 fade_xy = fade(Pf.xy);
    vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
    float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


void main(){
    
//    sum=.0;
//    for(int i=0;i<4;++i){
//        dr=particlePos[i][2];
//        dx=texCoord.x*window_width-particlePos[i][0];
//        dy=(1.0-texCoord.y)*window_height-particlePos[i][1];
//        sum+=dr*dr/(dx*dx+dy*dy);
//    }
//    if(sum>=1.0){
//        vec4 col = texture2D(Sampler, texCoord);
//        gl_FragColor = vec4(col);
//    }else{
        //gl_FragColor = vec4(0.0,0.0,0.0,0.0);
    if(draw_pattern==1){
        if( mod(floor(texCoord.x*window_width),2.0)!=0.0 || cnoise(vec2(texCoord.x*10.0,texCoord.y*20.0+frame_count*5.0))<.01){
//    if(cnoise(vec2(texCoord.x*20.0,texCoord.y*10.0+frame_count*5.0))<.01){
            gl_FragColor=vec4(0.0);
            return;
        }
    }
        vec4 c=texture2D(inputImageTexture, texCoord);
        float len=length(c);
//        if(len<.3) c=c+vec4(.5,.5,.5,0.0);
//        else if(len<.1) c=vec4(1.0);
    
    vec3 fragRGB = c.rgb;
    vec3 fragHSV = rgb2hsv(fragRGB).xyz;
//    fragHSV.x += vHSV.x / 360.0;
//    fragHSV.yz *= vHSV.yz;
//    fragHSV.xyz = mod(fragHSV.xyz, 1.0);
    fragHSV.y=clamp(fragHSV.y,.5,1.0);
    fragHSV.z=clamp(fragHSV.z,.5,1.0);
    fragRGB = hsv2rgb(fragHSV);
    
        gl_FragColor=vec4(fragRGB,1.0);
//        gl_FragColor=c;
    
//        gl_FragColor = vec4(0.0,0.0,1.0,1.0);
//        gl_FragColor = vec4(1.0,1.0,1.0,1.0);
    
//    }
}
