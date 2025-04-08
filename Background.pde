class Background {
  PImage treesImg;
  PImage mountainsImg;
  
  Background(String treesPath) {
    treesImg = loadImage(treesPath);
    // Load the mountain background image
    mountainsImg = loadImage("PixelArt_Samurai/Environment/PNG/Environment_Back_Mountain.png");
  }

  void display() {
    // Draw mountains in the background first
    // Scale the mountain image to fit the screen width
    float mountainScale = 2.0;  
    float mountainY = height - mountainsImg.height * mountainScale * 0.6;  // Position mountains higher in the background
    
    // Draw mountains across the screen
    for (int x = 0; x < width; x += mountainsImg.width * mountainScale) {
      image(mountainsImg, x + mountainsImg.width * mountainScale / 2, mountainY, 
            mountainsImg.width * mountainScale, mountainsImg.height * mountainScale);
    }
    
    // Then draw the trees in front
    boolean flip = false;
    for (int x = 0; x < width; x += treesImg.width) {
      pushMatrix();
      if (flip) {
        scale(-1, 1);
        image(treesImg, -x - treesImg.width / 2, height - treesImg.height / 2);
      } else {
        image(treesImg, x + treesImg.width / 2, height - treesImg.height / 2);
      }
      popMatrix();
      flip = !flip;
    }
  }
}