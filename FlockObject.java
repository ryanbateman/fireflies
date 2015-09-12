import static processing.core.PConstants.TWO_PI;
import processing.core.PVector;
import processing.core.PApplet;
import java.util.Random;

public abstract class FlockObject {

  protected int alphaValue;  
  protected PVector position;
  protected int size;
  
  protected float alphaDifference;
  protected float flockxoff;
  protected float flockyoff;
  protected float flockzoff;
  protected float resettingStrength; 
  int maximumSignalDistance = 200;

  protected boolean isGlowing;
  
  public FlockObject(PVector position) {
    resettingStrength = 0.12f;
    size = 25;
    this.position = position;
    isGlowing = false;
    
    Random random = new Random();
    alphaDifference = random.nextFloat() * TWO_PI;
    alphaValue = (int) (250 * 0.5 * (PApplet.sin(alphaDifference) + 1));
  }

  public void receiveSignal(PVector otherPosition, float pulseValue) {
    if (position.dist(otherPosition) < maximumSignalDistance) {
      alphaDifference = (float) (alphaDifference + (resettingStrength * Math.sin(alphaDifference - pulseValue)));
    }
  }

  public PVector getPosition() {
    return position;
  }

  abstract void drawBody();

  public void tick() {
    drawBody();
    calculateNextPosition();
  }
  
  abstract void calculateNextPosition();

}