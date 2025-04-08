// Modify the Coin class to not be a physics object
class Coin {
  private PVector position;
  private PImage[] coinFrames;
  private PImage[] destroyFrames;
  private float currentFrame = 0.0f;
  private boolean collected = false;
  private final float ANIMATION_SPEED = 0.2f;
  private float radius = 15.0f; // collision detection
  
  Coin(PVector position) {
    this.position = position.copy();
    
    coinFrames = new PImage[13];
    destroyFrames = new PImage[13];
    
    for (int i = 0; i < 13; i++) {
      String framePath = "CharacterPack/GPE/pickups/coin/coin_" + nf(i+1, 2) + ".png";
      coinFrames[i] = loadImage(framePath);
      
      String destroyPath = "CharacterPack/GPE/pickups/coin/destroy/coin_destroy_" + nf(i+1, 2) + ".png";
      destroyFrames[i] = loadImage(destroyPath);
    }
  }
  
  void update() {
    currentFrame += ANIMATION_SPEED;
    
    if (!collected) {
      if (currentFrame >= coinFrames.length) {
        currentFrame = 0;
      }
    } else {
      if (currentFrame >= destroyFrames.length) {
        currentFrame = destroyFrames.length - 1;
      }
    }
  }
  
  void draw() {
    PImage[] frames = collected ? destroyFrames : coinFrames;
    int frameIndex = min((int)currentFrame, frames.length - 1);
    
    
    pushStyle();
    
    // Draw the coin
    image(frames[frameIndex], position.x, position.y);
    popStyle();
  }
  
  boolean isCollected() {
    return collected;
  }
  
  void collect() {
    if (!collected) {
      collected = true;
      currentFrame = 0; // Reset frame to start destroy animation
    }
  }
}