import processing.opengl.*;
import com.jogamp.opengl.*;

PGraphicsOpenGL pgl;
PGL gl;
float angle = 0;
boolean paused = true;
int zoomDistance = -20;
boolean stopMovement = true;
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
    theFlock = new FlockObject[flockSize];
    b = loadImage("blur2.png");
    c = loadImage("blur4.png");
    body = loadImage("firebody.png");
    frameRate(45);

    for (int p=0; p < theFlock.length; p++) {
      theFlock[p] = new FireflyFlockObject(random(0.01, 1)); 
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
      colorMode(RGB, 1.0);
      stroke(0.8f, 0.8f, 0.8f, 0.2f);
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
      colorMode(RGB, 255);
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

public void signal(PVector position, float alphaValue) {
  for(int i = 0; i < flockSize; i++) {
    theFlock[i].receiveSignal(position, alphaValue);
  }    
}

private class FireflyFlockObject extends FlockObject {
  
  public FireflyFlockObject(float offset) {
    flockxoff = random(offset*.4, offset * 5.8);
    flockyoff = random(offset*.4, offset * 1.8);
    flockzoff = random(offset*.4, offset * 19.8);
    
    PVector position = new PVector(int(noise(flockxoff) * width),  int(noise(flockyoff) * width) , int(noise(flockzoff) * width));
    setPosition(position);
  }

  public void tick() {
    translate(position.x, position.y, position.z);
    drawBody();
    translate(-position.x, -position.y, -position.z);      
    calculateNextPosition();
  }
  
  public void calculateNextPosition() {
    position.set(int(noise(flockxoff) * width),  int(noise(flockyoff) * width), int(noise(flockzoff) * width));
    
    // Adjusting these values will adjust the speed with which the flockObjects tranverse the Perlin noise map and so vary / move
    if (stopMovement) {
      flockxoff += 0.008;
      flockyoff += 0.008; 
      flockzoff += 0.008;
    } 
  }

  public void drawBody() {
 
    alphaValue = int(sin(alphaDifference) * 250);
    alphaDifference += stopMovement ? 0.2 : -0.2;
    if (alphaValue >= 249) {
      isGlowing = false;
      signal(position, alphaDifference);     
    }
    
    if (alphaValue == 0) {
      isGlowing = true;
    }

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