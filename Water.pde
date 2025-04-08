class Water {
  float x, y, width, height;
  color waterColor;
  ArrayList<Ripple> ripples;
  
  Water(float x, float y, float width, float height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.waterColor = color(64, 164, 223, 150); // Semi-transparent blue
    this.ripples = new ArrayList<Ripple>();
  }
  
  void update() {
    // Update ripples and remove old ones
    for (int i = ripples.size() - 1; i >= 0; i--) {
      Ripple r = ripples.get(i);
      r.update();
      if (r.isDead()) {
        ripples.remove(i);
      }
    }
    
    // Occasionally add random ripples for ambient effect
    if (random(1) < 0.02) {
      float rippleX = random(x + 20, x + width - 20);
      float rippleSize = random(5, 15);
      ripples.add(new Ripple(rippleX, y, rippleSize));
    }
  }
  
  void draw() {
    // Draw the water body
    pushStyle();
    fill(waterColor);
    noStroke();
    rect(x, y, width, height);
    
    // Draw water surface with wave effect
    stroke(255, 255, 255, 100);
    strokeWeight(2);
    for (int i = 0; i < 3; i++) {
      float wavePeriod = 0.05;
      float amplitude = 3;
      
      beginShape();
      noFill();
      for (float wx = x; wx <= x + width; wx += 5) {
        float waveY = y + amplitude * sin(frameCount * wavePeriod + wx * 0.1 + i * PI/3);
        vertex(wx, waveY);
      }
      endShape();
    }
    
    // Draw ripples
    for (Ripple r : ripples) {
      r.draw();
    }
    popStyle();
  }
  
  boolean isPointSubmerged(PVector point) {
    return point.x >= x && point.x <= x + width && point.y >= y;
  }
  
  float getSubmersionDepth(PhysicsObject obj) {
    if (obj.position.y - obj.radius > y + height) {
      // Object is below the water
      return 0;
    }
    
    if (obj.position.y + obj.radius < y) {
      // Object is completely above water
      return 0;
    }
    
    float objBottom = obj.position.y + obj.radius;
    float objTop = obj.position.y - obj.radius;
    
    if (objTop >= y) {
      // Object is fully submerged
      return obj.radius * 2;
    } else {
      // Object is partially submerged
      return objBottom - y;
    }
  }
  
  void addRipple(float x, float y, float size) {
    // Add a ripple at the given point
    if (x >= this.x && x <= this.x + this.width) {
      ripples.add(new Ripple(x, this.y, size));
    }
  }
  
  //ripple effect
  class Ripple {
    float x, y;
    float radius;
    float maxRadius;
    float growthRate;
    float alpha;
    
    Ripple(float x, float y, float maxRadius) {
      this.x = x;
      this.y = y;
      this.radius = 0;
      this.maxRadius = maxRadius;
      this.growthRate = random(0.5, 1.5);
      this.alpha = 255;
    }
    
    void update() {
      radius += growthRate;
      alpha = 255 * (1 - radius / maxRadius);
    }
    
    void draw() {
      stroke(255, 255, 255, alpha);
      noFill();
      ellipse(x, y, radius * 2, radius / 2); // Ellipse with half the height
    }
    
    boolean isDead() {
      return radius >= maxRadius;
    }
  }
}