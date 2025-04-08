class PlatformStay implements SteeringBehavior {
  private float centerX;         // Platform center X position
  private float platformWidth;   // Width of the platform
  private float maxForce;        // Maximum steering force
  private float edgeThreshold;   // How close to edge before turning around
  
  public PlatformStay(float centerX, float platformWidth, float maxForce, float edgeThreshold) {
    this.centerX = centerX;
    this.platformWidth = platformWidth;
    this.maxForce = maxForce;
    this.edgeThreshold = edgeThreshold;
  }
  
  public PVector calculateForce(PhysicsObject obj) {
    // Calculate left and right edges of platform
    float leftEdge = centerX - platformWidth/2 + edgeThreshold;
    float rightEdge = centerX + platformWidth/2 - edgeThreshold;
    
    // Check if we're near the edges and turn around
    if (obj.position.x < leftEdge) {
      // Near left edge, steer right
      return new PVector(maxForce, 0);
    } 
    else if (obj.position.x > rightEdge) {
      // Near right edge, steer left
      return new PVector(-maxForce, 0);
    }
    
    // If not near edges, maintain current velocity
    return new PVector(0, 0);
  }
}