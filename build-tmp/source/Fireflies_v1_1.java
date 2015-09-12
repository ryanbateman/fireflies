import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.opengl.*; 
import javax.media.opengl.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Fireflies_v1_1 extends PApplet {




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
  public void setup() {
    size(700, 700, OPENGL);
    values = new int[width];
    theFlock = new FlockObject[flockSize];
    b = loadImage("blur2.png");
    c = loadImage("blur4.png");
    body = loadImage("firebody.png");
    frameRate(45);

    for (int p=0; p < theFlock.length; p++) {
      theFlock[p] = new FlockObject(random(0.01f, 1)); 
    }
  }

  public void draw() {
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
  camera(width / 2, height / 2, 1200, width/2.0f, height/2.0f, 450, 0, 1, 0); 
  
  if (paused == false) {
    angle += 0.05f;
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

public void keyPressed() {
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
    angle += 0.05f;  
  } else if (keyCode == 37) {
    // Left keycode
    angle -= 0.05f; 
  } else if (keyCode == 40) {
    zoomDistance -= 10;
  } else if (keyCode == 38) {
    zoomDistance += 10;  
  }
}

public void signal(PVector position, float alphaValue) {
  for(int i = 0; i < flockSize; i++) {
    theFlock[i].receiveSignal(position, alphaValue);
  }    
}

private class FlockObject {

  private int alphaValue;  
  private PVector position;
  private int size;
  
  private float alphaDifference;
  private float flockxoff;
  private float flockyoff;
  private float flockzoff;
  private float resettingStrength; 

  private boolean isGlowing;
  
  public FlockObject(float offset) {
    resettingStrength = 0.12f;
    size = PApplet.parseInt(random(5, 55));
    flockxoff = random(offset*.4f, offset * 5.8f);
    flockyoff = random(offset*.4f, offset * 1.8f);
    flockzoff = random(offset*.4f, offset * 19.8f);
    
    position = new PVector(PApplet.parseInt(noise(flockxoff) * width),  PApplet.parseInt(noise(flockyoff) * width) , PApplet.parseInt(noise(flockzoff) * width));

    isGlowing = false;
    alphaDifference = random(0, TWO_PI);
    alphaValue = PApplet.parseInt(250 * 0.5f * (sin(alphaDifference) + 1)); 
  }

  public void receiveSignal(PVector otherPosition, float pulseValue) {
    if (position.dist(otherPosition) < maximumSignalDistance) {
      alphaDifference = alphaDifference + (resettingStrength * sin(alphaDifference - pulseValue));
    }
  }

  public void tick() {
    translate(position.x, position.y, position.z);
    drawGlow();   
    drawBody();
    translate(-position.x, -position.y, -position.z);      
    calculateNextPosition();
  }
  
  private void calculateNextPosition() {
    position.set(PApplet.parseInt(noise(flockxoff) * width),  PApplet.parseInt(noise(flockyoff) * width), PApplet.parseInt(noise(flockzoff) * width));
    
    // Adjusting these values will adjust the speed with which the flockObjects tranverse the Perlin noise map and so vary / move
    if (stopMovement) {
      flockxoff += 0.008f;
      flockyoff += 0.008f; 
      flockzoff += 0.008f;
    } 
  }

  private void drawGlow() {
   if (showGlow) {
    alphaValue = PApplet.parseInt(sin(alphaDifference) * 250);
    alphaDifference += stopMovement ? 0.2f : -0.2f;
    if (alphaValue >= 249) {
      isGlowing = false;
      signal(position, alphaDifference);     
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
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Fireflies_v1_1" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
