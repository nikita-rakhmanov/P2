// Node class for A* pathfinding
class Node {
  PVector position; // Grid position (x,y)
  float f, g, h;    // f = g + h (total cost, path cost, heuristic)
  Node parent;      // Parent node for path reconstruction
  boolean walkable; // Can the enemy walk on this node?
  
  Node(PVector position, boolean walkable) {
    this.position = position;
    this.walkable = walkable;
    this.f = 0;
    this.g = 0;
    this.h = 0;
    this.parent = null;
  }
  
  // Equality check based on grid position
  boolean equals(Node other) {
    return this.position.x == other.position.x && this.position.y == other.position.y;
  }
}