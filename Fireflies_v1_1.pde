import processing.opengl.*;
import javax.media.opengl.*;

PGraphicsOpenGL pgl;
PGL gl;
int[] values;
float angle = 0;
boolean paused = true;
boolean showGlow = true;
int zoomDistance = -10;
boolean stopMovement = true;
int maximumSignalDistance = 200;
boolean drawAxis = true;
boolean drawLines = false;
FlockObject[] theFlock;
PImage b, c, body; 

int flockSize = 150;

/*
  This program models the noise over an X-axis 
  and allows for simple rotation of the view, as
  well as the addition of boxes at the new noise value points
*/
void setup() {
  size(700, 700, OPENGL);
  values = new int[width];
  theFlock = new FlockObject[flockSize];
  b = loadImage("blur2.png");
  c = loadImage("blur4.png");
  body = loadImage("firebody.png");
  frameRate(45);

  for (int p=0; p < theFlock.length; p++) {
    theFlock[p] = new FlockObject(random(0.01, 1), str(p)); 
  }
}

void draw() {
  setupEnvironment();
  tick();
  tearDownEnvironment();
}

private void tick() {
  for (int p = 0; p < theFlock.length; p++) {
    theFlock[p].tick();
  }
}

private void drawAxes() {  
  if (drawAxis) {    
    stroke(75);
    line(0, 0, height , 0);
    line(0, height, 0, 0, height, height);
    line(height, height, 0, height, height, height);
    for (int i = 0; i <= width; i += 20) {
      line(0, height, i, width , height, i);
      line(0, i, 0, width, i, 0);
    }
    for (int i = 0; i <= width; i += 20) {
      line(i, 0, i , height);
      line(i, width, 0, i, width, width);
    }
    stroke(0);
  }
}

private void setupEnvironment() {
  background(0);
  pgl = (PGraphicsOpenGL) g;   
  gl = pgl.beginPGL();         
  gl.disable(PGL.DEPTH_TEST);
  gl.enable(PGL.BLEND);
  gl.blendFunc(PGL.SRC_ALPHA, PGL.ONE);
  
  // Rotate around the center axis
  camera(width / 2, height / 2, 1200, width/2.0, height/2.0, 450, 0, 1, 0); 
  
  if (paused == false) {
    angle += 0.05;
    if (angle > TWO_PI) { 
      angle = 0; 
      paused = true;
    }
  }
  translate(width/2, 0, zoomDistance);
  rotateY(angle);
  translate(-width/2, 0, zoomDistance);
  
  drawAxes();
}

private void tearDownEnvironment() {
  
  pgl.beginPGL();
  gl.depthMask(true);
  gl.blendFunc(PGL.SRC_ALPHA, PGL.ONE_MINUS_SRC_ALPHA);
  pgl.endPGL();  
}

void keyPressed() {
  if (keyCode == ENTER) {
    paused = !paused;
  } else if (key == ' ') {
    stopMovement = !stopMovement; 
  } else if (key == 'l') {
    drawLines = !drawLines; 
  } else if (key == 'a') {
    drawAxis = !drawAxis; 
  } else if (key == 'g') {
    showGlow = !showGlow; 
  } else if (keyCode == 39) {
    // Right keycode
    angle += 0.05;  
  } else if (keyCode == 37) {
    // Left keycode
    angle -= 0.05; 
  } else if (keyCode == 40) {
    zoomDistance -= 10;
  } else if (keyCode == 38) {
    zoomDistance += 10;  
  }
}

public void signal(int posX, int posY, int posZ, float alphaValue) {
  for(int i = 0; i < flockSize; i++) {
    theFlock[i].receiveSignal(posX, posY, posZ, alphaValue);
  }    
}

private class FlockObject {

  private int alphaValue;  
  private int positionX;
  private int positionY;
  private int positionZ;
  private int newpositionX;
  private int newpositionY;
  private int newpositionZ;
  private int size;
  
  private float alphaDifference;
  private float flockxoff;
  private float flockyoff;
  private float flockzoff;
  private float resettingStrength; 
   
  private boolean isGlowing;
   
  private String name;
  
  public FlockObject(float offset, String name) {
    resettingStrength = 0.12;
    this.name = name;
    size = int(random(5, 55));
    flockxoff = random(offset*.4, offset * 5.8);
    flockyoff = random(offset*.4, offset * 1.8);
    flockzoff = random(offset*.4, offset * 19.8);
    
    isGlowing = false;
    alphaDifference = random(0, TWO_PI);
    alphaValue = int(250 * 0.5 * (sin(alphaDifference) + 1)); 
     
    positionX = int(noise(flockxoff) * width);
    positionY = int(noise(flockyoff) * width);
    positionZ = int(noise(flockzoff) * width);
  }
 
  public int getPosX() {
    return positionX;
  }
  
  public int distanceAway(int otherPosX, int otherPosY, int otherPosZ) {
    int dX = positionX - otherPosX;
    int dY = positionY - otherPosY;
    int dZ = positionZ - otherPosZ;
    return int(sqrt(sq(dX) + sq(dY) + sq(dZ)));
  } 
 
  public void receiveSignal(int otherPosX, int otherPosY, int otherPosZ, float pulseValue) {
    if (distanceAway(otherPosX, otherPosY, otherPosZ) < maximumSignalDistance) {
      alphaDifference = alphaDifference + (resettingStrength * sin(alphaDifference - pulseValue));
    }
  }
 
  public int getPosY() {
    return positionY;
  }
 
  public int getPosZ() {
   return positionZ;
  }
 
  public void tick() {
    translate(positionX, positionY, positionZ);
    drawGlow();   
    drawBody();
    translate(-positionX, -positionY, -positionZ);      
    calculateNextPosition();
  }
  
  private void calculateNextPosition() {
    positionX = int(noise(flockxoff) * width);
    positionY = int(noise(flockyoff) * width);
    positionZ = int(noise(flockzoff) * width);
    
    // Adjusting these values will adjust the speed with which the flockObjects tranverse the Perlin noise map and so vary / move
    if (stopMovement) {
      flockxoff += 0.008;
      flockyoff += 0.008; 
      flockzoff += 0.008;
    } 
  }
    
  private void drawGlow() {
   if (showGlow) {
      alphaValue = int(sin(alphaDifference) * 250);
      alphaDifference += stopMovement ? 0.2 : -0.2;
      if (alphaValue >= 249) {
        isGlowing = false;
        signal(positionX, positionY, positionZ, alphaDifference);     
      }
    
      if (alphaValue == 0) {
        isGlowing = true;
      }
    } 
  }
  
  private void drawBody() {
    int compensateZ = (int) (size * sin(angle));
    int compensateX = (int) (size * sin(angle + (PI / 2)));
    
    beginShape();
    tint(192, alphaValue);
    texture(b);
    vertex(- compensateX, -size, -compensateZ, 0, 0);
    vertex(compensateX, -size, compensateZ, 200, 0);
    vertex(compensateX, size, compensateZ, 200, 200);
    vertex(-compensateX, size, - compensateZ, 0, 200);
    endShape();
    
    noTint();   
    beginShape();
    texture(body);
    vertex(- compensateX, -size, -compensateZ, 0, 0);
    vertex(compensateX, -size, compensateZ, 200, 0);
    vertex(compensateX, size, compensateZ, 200, 200);
    vertex(-compensateX, size, - compensateZ, 0, 200);
    endShape();
  }
 
}
