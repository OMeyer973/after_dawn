import ddf.minim.*;
import ddf.minim.analysis.*;

//constants
int Y_AXIS = 1;
int X_AXIS = 2;


//audio computing variables
Minim minim;
AudioInput song;
FFT fft;
float smoothLevel;

PGraphics sky;
PGraphics bg2D;
PGraphics cloudsFrame;
PGraphics canvas3D;

//2D variables
//ground
float farWidth = 1;
float nearWidth = 1;
//clouds
float borderWidth = width/30;
int nbClouds = 50;
int nbCloudBands = 8;
float minCloudSize = 10;
float maxCloudSize = 30;
//sky
int nbStars = 1500;
int starSize = 5;
float baseSkySpeed = 2;
float skySpeed = baseSkySpeed;
float skyPos = 0;
float starPos[][];


color cSky = #000000;
color cStar = #ffffff;
//clouds
color cBorder = #4F5A60;
color cClouds[];
//ground colors
color cGroundDark = #1C4271;
color cGroundBase1 = #6161CE;
color cGroundBase2 = #607AD1;
//hill colors
color cHillDark = #2F67A2;
color cHillBase = #8199FD;
color cHillLight = #C9D7FA;

//3D varaibles
int nbHills = 15;
int nbFreq = 200;
float hillSpacing = width*2;
float hillTab[][];
float noiseTab[][];
float hillShapeTab[];
int noiseId = 0;

int nbParticles = 70;
Point particles[];
float particleSize = 500;
float particleRotSpeed = 0.5;

float baseCamSpeed = 20;
float camSpeed = baseCamSpeed;
float camPos = 0;
float camPos2 = 0;

void setup() {
  size(1000, 1000, P2D);
  
  // always start Minim first!
  minim = new Minim(this);
  song = minim.getLineIn();
  fft = new FFT(song.bufferSize(), song.sampleRate());
  
  farWidth = width/4;
  nearWidth = width*1.5;
  hillSpacing = width*2;
  
  cClouds = new color[10];
  cClouds[0] = #071230;
  cClouds[1] = #144E66;
  cClouds[2] = #2E76B1;
  cClouds[3] = #5FBBE2;
  cClouds[4] = #EAFFFB;
  cClouds[5] = #DB9AF4;
  cClouds[6] = #F383D7;
  cClouds[7] = #FFA7F9;
  cClouds[8] = #CE7AC8;
  cClouds[8] = #A17DDF;
  
  starPos = new float[nbStars][6];
  hillTab = new float[nbHills][nbFreq];
  noiseTab = new float[nbHills][nbFreq];
  hillShapeTab = new float[nbFreq];
  
  for(int i=0; i<nbStars; i++) {
    starPos[i][0] = random(0,width);
    starPos[i][1] = random(0,height);
    for(int j=2; j<6; j++) {
      starPos[i][j] = starPos[i][j%2] + 3.5 * starSize * (noise(starPos[i][j%2]*j)-0.5);      
    }
  }
  
  particles = new Point[nbParticles];
  for(int i=0; i<nbParticles; i++) {
    float r = random(3);
    color c = cHillDark;
    if (r < 1) c = cGroundDark;
    if (2 < r) c = cHillLight;
    particles[i] = new Point(random(-2*height, 2*height),random( -height/2,0),random(-height,0),c);
  }
  
  for(int i=0; i<nbHills; i++) {
    for(int j=0; j<nbFreq; j++) {
      hillTab[i][j] = 0;
      hillShapeTab[j] = 0.55+cos((float(j)/nbFreq-0.15)*2*PI*1.4)/2;
      noiseTab[i][j] = random(-0.1,0.5);
    }
  }
  
  canvas3D = createGraphics(width, height, P3D);
  bg2D = createGraphics(width, height, P2D);
  cloudsFrame = createGraphics(int(farWidth), height/2, P2D);
  sky = createGraphics(width, height, P2D);
  makeSky(sky);
  draw2DBG(bg2D);
}

void makeSky(PGraphics sky) {
  sky.beginDraw();
    sky.fill(cStar);
    sky.noStroke();
    for (int i=0; i <nbStars; i++) {
      sky.triangle(starPos[i][0], starPos[i][1], starPos[i][2], starPos[i][3], starPos[i][4], starPos[i][5]);
    }
  sky.endDraw();
}
//END SETUP
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//BEGIN LOOP  
void draw() {
  fft.forward(song.mix);
  smoothLevel = flerp(smoothLevel, song.mix.level(), 0.1);
  draw2DBG(bg2D);
  // draw a simple rotating cube around a sphere
  draw3D(canvas3D);
  
  drawClouds(cloudsFrame);
}

void drawClouds (PGraphics c) {
  c.beginDraw();
    c.background(getCloudColor(c,mouseX/width));
    c.fill(cStar);
    c.noStroke();
    
    for (int i=0; i < nbCloudBands; i++) {
      getCloudColor(c,1-float(i)/nbCloudBands);
      for (int j=0; j < nbClouds; j++) {
        float r = random(minCloudSize,maxCloudSize);
        c.ellipse(random(c.width), 
                random(c.height*i/nbCloudBands,c.height*(i+1)/nbCloudBands),
                r,r);
      }
    }
    
  c.endDraw();
  image(c,(width-int(farWidth))/2, 0);
  
  stroke(cBorder);
  strokeWeight(borderWidth);
  line((width-int(farWidth))/2-2*borderWidth,0,(width-int(farWidth))/2-2*borderWidth,height/2);
  line((width+int(farWidth))/2+2*borderWidth,0,(width+int(farWidth))/2+2*borderWidth,height/2);
}

//gets the color for the cloud at height i (0-1)
color getCloudColor(PGraphics c, float k) {
  int inf = 0;
  int sup = 1;
  for (int i=0; i<cClouds.length; i++) {
    if (k > float(i)/cClouds.length) {
      inf = i;
      sup = i+1;
      i = cClouds.length;
    }
  }
  float step = (k-float(inf)/cClouds.length)/(float(sup)/cClouds.length);
  c.fill(lerpColor(cClouds[inf],cClouds[sup],step));
  return(lerpColor(cClouds[inf],cClouds[sup],step));
}

void draw2DBG(PGraphics bg) {
  bg.beginDraw();
  skySpeed = flerp(skySpeed,baseSkySpeed*smoothLevel, 0.02);
    skyPos -= skySpeed * camSpeed/15;
    if (skyPos < -height) {
      skyPos += height;
    }
    
    bg.background(cSky);
    bg.image(sky,0,skyPos);
    bg.image(sky,0,skyPos+height);
    setGradient(bg, 0, height/2, width, height, cGroundBase1, cGroundBase2, Y_AXIS);
    bg.fill(cGroundDark);
    bg.triangle(0,height/2,-(nearWidth-width)/2,height,(width-farWidth)/2,height/2);
    bg.triangle(width,height/2,width+(nearWidth-width)/2,height,width-(width-farWidth)/2,height/2);
  bg.endDraw();
  image(bg,0,0);
}

void draw3D(PGraphics c) {
  float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
  c.perspective(PI/2, float(width)/float(height), cameraZ/10.0, height*200.0);
    makeHillTab();
    
    camSpeed = flerp(camSpeed, 10*baseCamSpeed  * smoothLevel, 0.1);
    camPos += camSpeed;
    if (camPos > hillSpacing) {
      camPos -= hillSpacing;
      noiseId++;
    }
    camPos2 += camSpeed;
    if (camPos2 > 2 * hillSpacing) {
      camPos2 -= 2 * hillSpacing;
    }
    
    c.beginDraw();
    c.background(cGroundDark);
    c.clear();
    c.pushMatrix();
      c.translate(0,0,camPos);
      c.translate(width / 2, height, width);
      for(int i=0; i<nbHills; i++) {  
         drawHill(c,i);
         drawParticles(c,i);
      }
    c.popMatrix();
  c.endDraw();
  
  image(canvas3D,0,0);
}


void makeHillTab() {
   for(int i=0; i<nbHills; i++) {        
      for(int j=0; j<nbFreq; j++) {        
        hillTab[i][j] = flerp(hillTab[i][j], log(fft.getBand(j)*10+1)*0.2, 0.6*i/nbHills);
      }  
   }
}

void drawHillBase(PGraphics c, int hillId, int noiseID, float coef, float x, float y, float w, float h) {
  c.beginShape(TRIANGLE_STRIP); 
  for(float i=0; i<nbFreq; i++) {        
    c.vertex(x+i*w/nbFreq,y);
    c.vertex(x+i*w/nbFreq,y+h*coef*(hillTab[hillId][int(i)]*hillShapeTab[int(i)]*30+coef/10+noiseTab[noiseID][int(i)]) );
  }
  c.endShape();
}

//dessine la coline i dans le canvas c
void drawHill(PGraphics c, int i) {
  c.pushMatrix();
  c.translate(0,0,-hillSpacing*i);
  c.rotateY(-PI/5);// *(nbHills-float(i))/nbHills);
  c.noStroke();
  c.fill(cHillBase);
  drawHillBase(c, i, (i+1+noiseId)%nbHills, 1.1, -20*width, 0, 40*width, -100);
  c.translate(0,1,0);
  c.fill(cHillDark);
  drawHillBase(c, i, (i+noiseId)%nbHills, 0.8, -20*width, 0, 40*width, -100);
  
  c.rotateX(-PI/2);
  c.fill(cGroundDark);
  drawHillBase(c, i, (i+1+noiseId)%nbHills, 4, -20*width, 0, 40*width, -100);
  c.fill(cHillDark);
  c.translate(0,0,-1);
  drawHillBase(c, i, (i+1+noiseId)%nbHills, 1.5, -20*width, 0, 40*width, -100);
  
  c.popMatrix();
}

void drawParticles(PGraphics c, int k) {
  
  c.pushMatrix();
  c.translate(0,0,-camPos2/2);   
  c.translate(0,0,-hillSpacing*k);
  c.noStroke();
  
  for(int i=0; i<nbParticles; i++) {
    c.fill(particles[i].c);
    c.pushMatrix();
      c.translate(particles[i].x,particles[i].y,particles[i].z);
      c.rotateX(particles[i].y+radians(frameCount*particleRotSpeed % 360));
      c.rotateY(particles[i].z+radians(frameCount*particleRotSpeed % 360));
      c.triangle(0,0,0,particleSize*smoothLevel,particleSize*smoothLevel,0);
    c.popMatrix();
  }
  c.popMatrix();
}



void setGradient(PGraphics canvas, int x, int y, float w, float h, color c1, color c2, int axis ) {

  noFill();
  if (axis == Y_AXIS) {  // Top to bottom gradient
    for (int i = y; i <= y+h; i++) {
      float inter = map(i, y, y+h, 0, 1);
      color c = lerpColor(c1, c2, inter);
      canvas.stroke(c);
      canvas.line(x, i, x+w, i);
    }
  }  
  else if (axis == X_AXIS) {  // Left to right gradient
    for (int i = x; i <= x+w; i++) {
      float inter = map(i, x, x+w, 0, 1);
      color c = lerpColor(c1, c2, inter);
      canvas.stroke(c);
      canvas.line(i, y, i, y+h);
    }
  }
}


//lerp on floats
float flerp(float a, float b, float f) 
{
  return (a * (1.0 - f)) + (b * f);
}

float clamp(float a, float b, float c) {
  return min(max(a, b), c);
}


class Point {
  float x;
  float y;
  float z;
  color c;
  Point(float x, float y, float z, color c) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.c = c;
  }
  void setXY(float x, float y, float z, color c) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.c = c;
  }
}