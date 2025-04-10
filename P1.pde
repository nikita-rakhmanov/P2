Background bg;
Character character;
Platform ground;
ArrayList<Enemy> enemies = new ArrayList<Enemy>();
ArrayList<Spring> springs = new ArrayList<Spring>();
ArrayList<PlatformObject> platforms = new ArrayList<PlatformObject>();
ArrayList<Coin> coins = new ArrayList<Coin>();
boolean attackLanded = false;
boolean gameOver = false;
boolean gameStarted = false;
PhysicsEngine physicsEngine;
long gameStartTime = 0;
long gameEndTime = 0;
boolean timerRunning = false;

class PlatformObject extends PhysicsObject {
  PImage platformImage;
  
  PlatformObject(float x, float y) {
    super(new PVector(x, y), 0.0f); 
    this.isStatic = true;
    this.radius = 25.0f;
    
    // Load the platform image
    platformImage = loadImage("CharacterPack/GPE/platforms/platform_through.png");
  }
  
  void draw() {
    image(platformImage, position.x, position.y);
  }
}

void setup() {
  size(1024, 768);
  noSmooth();
  imageMode(CENTER);
  textMode(CENTER);

  // physics engine
  physicsEngine = new PhysicsEngine();

  // Load background and ground
  bg = new Background("CharacterPack/Enviro/BG/trees_bg.png");
  ground = new Platform("CharacterPack/GPE/platforms/platform_through.png");
  
  // Create character in the middle
  character = new Character(new PVector(width / 2, height - 30));
  
  // Create enemies on both sides with FSM-based behaviors
  Enemy enemy1 = new Enemy(new PVector(width / 4, height - 30), character);
  Enemy enemy2 = new Enemy(new PVector(width * 3 / 4, height - 30), character);
  Enemy enemy3 = new Enemy(new PVector(width * 0.35f, height - 330 - 20), character); 
  Enemy enemy4 = new Enemy(new PVector(width * 0.65f, height - 330 - 20), character); 

  enemies.add(enemy1);
  enemies.add(enemy2);
  enemies.add(enemy3);
  enemies.add(enemy4);

  // Each enemy will now use its FSM to determine behavior
  // But we can configure each one with different initial states or parameters

  // Enemy 1: Aggressive chaser - starts in chase state
  enemies.get(0).fsm.forceState(EnemyState.CHASE);

  // Enemy 2: Patroller that becomes aggressive when player is nearby
  enemies.get(1).fsm.forceState(EnemyState.PATROL);

  // Enemy 3: Idle until player approaches, then attacks
  enemies.get(2).fsm.forceState(EnemyState.IDLE);

  // Enemy 4: Patrol with flee behavior when player approaches
  enemies.get(3).fsm.forceState(EnemyState.PATROL);
  // Add a flee behavior with high weight to make this enemy more evasive
  enemies.get(3).steeringController.addBehavior(new Flee(character.position, 0.9f, 150), 0.8f);

  float platformWidth = 32; // width of platform_through.png

  // enemies.get(0).steeringController.clearBehaviors();
  // enemies.get(0).steeringController.addBehavior(new Seek(character.position, 0.7), 1.0);

  // // Enemy 2: Mix of seeking player and wandering - less predictable hunter
  // enemies.get(1).steeringController.clearBehaviors();
  // enemies.get(1).steeringController.addBehavior(new Seek(character.position, 0.4), 0.6);
  // enemies.get(1).steeringController.addBehavior(new Wander(0.3, 50, 30), 0.4);

  // float platform3LeftX = width * 0.35f - platformWidth - platformWidth/2; // Leftmost edge of left platform
  // float platform3RightX = width * 0.35f + platformWidth + platformWidth/2; // Rightmost edge of right platform
  // float platform3Y = height - 330 - 8; // Approximate top surface of platform (-8 for visual adjustment)

  // // Enemy 3: Wander on platform - increase wander parameters
  // enemies.get(2).steeringController.clearBehaviors();
  // enemies.get(2).steeringController.addBehavior(
  //   new BoundedWander(0.18, 30, 15, platform3LeftX, platform3RightX, platform3Y), 1.0);
  // // Enemy 4: Wander on platform and flee from player
  // enemies.get(3).steeringController.clearBehaviors();
  // enemies.get(3).steeringController.addBehavior(new Flee(character.position, 0.9, 150), 0.7);
    
  // Create platforms for vertical traversal 
  // First layer - low platforms 
  platforms.add(new PlatformObject(width * 0.25f - platformWidth, height - 150)); 
  platforms.add(new PlatformObject(width * 0.25f, height - 150));                
  platforms.add(new PlatformObject(width * 0.25f + platformWidth, height - 150));
  
  platforms.add(new PlatformObject(width * 0.75f - platformWidth, height - 150)); 
  platforms.add(new PlatformObject(width * 0.75f, height - 150));                 
  platforms.add(new PlatformObject(width * 0.75f + platformWidth, height - 150));
  
  // Second layer - middle platforms 
  platforms.add(new PlatformObject(width * 0.5f - platformWidth, height - 270));
  platforms.add(new PlatformObject(width * 0.5f, height - 270));                
  platforms.add(new PlatformObject(width * 0.5f + platformWidth, height - 270)); 
  
  // Third layer - higher platforms
  platforms.add(new PlatformObject(width * 0.35f - platformWidth, height - 330)); 
  platforms.add(new PlatformObject(width * 0.35f, height - 330));                 
  platforms.add(new PlatformObject(width * 0.35f + platformWidth, height - 330)); 
  
  platforms.add(new PlatformObject(width * 0.65f - platformWidth, height - 330)); 
  platforms.add(new PlatformObject(width * 0.65f, height - 330));                
  platforms.add(new PlatformObject(width * 0.65f + platformWidth, height - 330)); 
  
  // Fourth layer - high platforms 
  platforms.add(new PlatformObject(width * 0.5f - platformWidth, height - 410)); 
  platforms.add(new PlatformObject(width * 0.5f, height - 490));                 
  platforms.add(new PlatformObject(width * 0.5f + platformWidth, height - 410)); 
  
  // Add springs at strategic locations 
  springs.add(new Spring(new PVector(width * 0.15f, height - 20))); // Left lower spring
  springs.add(new Spring(new PVector(width * 0.85f, height - 20))); // Right lower spring
  springs.add(new Spring(new PVector(width * 0.5f, height - 150))); // Middle spring on first platform
  
  // Add a coin on the top platform
  coins.add(new Coin(new PVector(width * 0.5f, height - 510 - 10))); 
  
  // Add objects to physics engine
  physicsEngine.addObject(character);
  for (Enemy enemy : enemies) {
    physicsEngine.addObject(enemy);
  }
  
  for (Spring spring : springs) {
    physicsEngine.addObject(spring);
  }
  
  for (PlatformObject platform : platforms) {
    physicsEngine.addObject(platform);
  }
  
  // Add force generators
  GravityForce gravity = new GravityForce(1.5f);
  DragForce drag = new DragForce(0.01f);
  
  // Apply forces to character
  physicsEngine.addForceGenerator(character, gravity);
  physicsEngine.addForceGenerator(character, drag);
  
  // Apply forces to enemies
  for (Enemy enemy : enemies) {
    physicsEngine.addForceGenerator(enemy, gravity);
    physicsEngine.addForceGenerator(enemy, drag);
  }
}

// Update keyPressed to start the timer when the game begins
void keyPressed() {
  if (!gameStarted) {
    if (key == ENTER || key == RETURN) {
      gameStarted = true;
      // Start the timer when the game begins
      gameStartTime = millis();
      timerRunning = true;
    }
  } else if (!gameOver) { // Only process inputs when game is active
    character.handleKeyPressed(key);
  } else if (key == 'r' || key == 'R') { // Allow restart with 'R' key
    resetGame();
  }
}

void keyReleased() {
  if (gameStarted && !gameOver) { // Only process inputs when game is active
    character.handleKeyReleased(key);
  }
}

void mousePressed() {
  if (gameStarted && !gameOver && mouseButton == LEFT) { // Only process inputs when game is active
    character.shoot();
  }
}

void draw() {
  background(0);
  bg.display();
  ground.display();
  
  if (!gameStarted) {
    displayStartScreen();
    return;
  }
  
  if (!gameOver) {
    // Update physics engine
    physicsEngine.update();
    
    // Update character and enemies
    character.update();
    for (Enemy enemy : enemies) {
      enemy.update();
    }
    
    // Update and check coins 
    updateCoins();
    
    // Handle bullet collisions with all enemies
    handleBulletCollisions();
    
    // Handle attack collisions with all enemies
    handleAttackCollisions();
    
    // Check if any enemy is attacking the player
    handleEnemyAttacks();
    
    // Check if player is dead
    if (character.isDead) {
      gameOver = true;
    }
    
    // Check for platform collisions
    handlePlatformCollisions();
    handleEnemyPlatformCollisions();
  }
  
  // Check for spring collisions
  checkSprings();
  
  // Draw all game objects
  drawGameObjects();
  displayHUD();
}

void handleBulletCollisions() {
  ArrayList<Bullet> bullets = character.getBullets();
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet bullet = bullets.get(i);
    boolean hitDetected = false;
    
    for (Enemy enemy : enemies) {
      if (!hitDetected && bullet.isActive() && !enemy.isDead && 
          PVector.dist(bullet.position, enemy.position) < enemy.radius + bullet.radius) {
        // Hit detected
        PVector force = PVector.sub(enemy.position, bullet.position).normalize().mult(5);
        force.y = -5; // Add upward force
        enemy.applyForce(force);
        enemy.takeDamage(10);
        bullet.deactivate();
        bullets.remove(i);
        hitDetected = true;
      }
    }
  }
}

void handleAttackCollisions() {
  if (character.isAttacking() && character.isAttackCollisionFrame()) {
    for (Enemy enemy : enemies) {
      if (!enemy.isDead && character.isInAttackRange(enemy)) {
        if (!attackLanded) {
          PVector force = PVector.sub(enemy.position, character.position).normalize().mult(10);
          force.y = -10; // Add upward force
          enemy.applyForce(force);
          enemy.takeDamage(20);
          attackLanded = true;
        }
      }
    }
  } else {
    attackLanded = false;
  }
}

void handleEnemyAttacks() {
  for (Enemy enemy : enemies) {
    if (enemy.isAttacking() && enemy.isInAttackRange(character) && 
        enemy.isInAttackCollisionFrame() && !character.isDead) {
      PVector force = PVector.sub(character.position, enemy.position).normalize().mult(10);
      force.y = -10;
      character.applyForce(force);
      character.takeDamage(10);
    }
  }
}

void handlePlatformCollisions() {
  // Get character's position 
  float characterFeetY = character.position.y + character.radius;
  float characterLeftX = character.position.x - character.radius * 0.8;
  float characterRightX = character.position.x + character.radius * 0.8;
  
  boolean wasOnPlatform = false;
  
  // First check if character is on the  ground
  if (character.position.y >= height - 30) {
    // character.position.y = height - 30 - character.radius;
    character.velocity.y = 0;
    character.fallingDown = false;
    character.jumpStartY = character.position.y;
    wasOnPlatform = true;
  } else {
    // Check platforms
    for (PlatformObject platform : platforms) {
      // Calculate platform bounds based on image dimensions
      float platformWidth = platform.platformImage.width;
      float platformHeight = platform.platformImage.height;
      float platformTopY = platform.position.y - platformHeight/2;
      float platformLeftX = platform.position.x - platformWidth/2;
      float platformRightX = platform.position.x + platformWidth/2;
      
      // Check horizontal overlap
      boolean horizontalOverlap = characterRightX > platformLeftX && characterLeftX < platformRightX;
      
      if (horizontalOverlap) {
        // Check if character is near the top of the platform and falling
        boolean isFallingOntoTop = character.velocity.y >= 0 && 
                                characterFeetY >= platformTopY && 
                                characterFeetY <= platformTopY + 15;
        
        if (isFallingOntoTop) {
          // Place character on top of platform
          character.position.y = platformTopY - character.radius;
          character.velocity.y = 0;
          character.fallingDown = false;
          character.jumpStartY = character.position.y;
          wasOnPlatform = true;
          break;
        }
      }
    }
  }
  
  // Always set falling state if not on platform and not jumping
  if (!wasOnPlatform && !character.jumpingUp) {
    character.fallingDown = true;
    
    // Apply gravity immediately when falling off platform edge
    if (character.velocity.y == 0) {
      character.velocity.y = 0.1; // Small initial downward velocity
    }
  }
}

void handleEnemyPlatformCollisions() {
  float groundLevel = height;
  
  for (Enemy enemy : enemies) {
    if (enemy.isDead) continue;
    
    float enemyFeetY = enemy.position.y + enemy.radius - 5;
    boolean onSomething = false;
    
    // Check if enemy is on the ground
    if (enemyFeetY >= groundLevel) {
      enemy.position.y = groundLevel - enemy.radius;
      enemy.velocity.y = 0;
      onSomething = true;
    } 
    // Only check platforms if enemy is above ground level
    else {
      // Check if enemy is on any platform
      for (PlatformObject platform : platforms) {
        float platformWidth = platform.platformImage.width;
        float platformHeight = platform.platformImage.height;
        float platformTopY = platform.position.y - platformHeight/2;
        float platformLeftX = platform.position.x - platformWidth/2;
        float platformRightX = platform.position.x + platformWidth/2;
        
        // Check if enemy is horizontally within platform bounds
        if (enemy.position.x + enemy.radius * 0.8 >= platformLeftX && 
            enemy.position.x - enemy.radius * 0.8 <= platformRightX) {
          
          // Check if enemy is on this platform (feet at platform level)
          if (Math.abs(enemyFeetY - platformTopY) < 5) {
            enemy.position.y = platformTopY - enemy.radius;
            enemy.velocity.y = 0;
            onSomething = true;
            break;
          }
        }
      }
    }
    
    // If enemy is not on ground or any platform, ensure they fall
    if (!onSomething && enemy.velocity.y <= 0) {
      enemy.velocity.y = 0.1; // Start falling if not already falling
    }
  }
}



void checkSprings() {
  for (Spring spring : springs) {
    // Calculate distance between character's feet and spring's top surface
    float characterFeetY = character.position.y + character.getRadius();
    float springTopY = spring.position.y - spring.platformImage.height/2;
    
    // collision check
    boolean isAboveSpring = abs(character.position.x - spring.position.x) < spring.platformImage.width/2 * 0.7f;
    boolean isTouchingSpring = characterFeetY >= springTopY - 10 && characterFeetY <= springTopY + 10;
    boolean isFalling = character.velocity.y > 1.0;
    
    if (isAboveSpring && isTouchingSpring && isFalling) {
      character.position.y = springTopY - character.getRadius();
      
      if (spring.compress()) {
        // Clear any accumulated forces that might counteract the bounce
        character.clearForces();
        
        // Apply upward velocity
        character.velocity.y = -spring.getBounceForce();
        
        // Add a horizontal boost in the direction the character is moving
        if (character.velocity.x != 0) {
          character.velocity.x *= 1.3; // Increase horizontal momentum by 30%
        }
        
        // Set spring bounce state
        character.setSpringBounce(true);
        character.jumpingUp = true;
        character.fallingDown = false;
        character.jumpStartY = character.position.y;

        // visual effect for jump
        pushStyle();
        fill(255, 255, 0, 150); 
        noStroke();
        ellipse(spring.position.x, spring.position.y, 100, 50); 
        
        // particles
        for (int i = 0; i < 10; i++) {
          float particleX = spring.position.x + random(-40, 40);
          float particleY = spring.position.y + random(-10, 10);
          fill(255, random(200, 255), 0, 200);
          ellipse(particleX, particleY, random(5, 15), random(5, 15));
        }
        popStyle();
      }
    }
  }
}

void drawGameObjects() {
  // Draw platforms
  for (PlatformObject platform : platforms) {
    platform.draw();
  }
  
  // Draw springs
  for (Spring spring : springs) {
    spring.draw();
  }
  
  // Draw coins
  for (Coin coin : coins) {
    coin.draw();
  }
  
  // Draw character
  character.draw();
  
  // Draw enemies
  for (Enemy enemy : enemies) {
    enemy.draw();
  }
}

void displayHUD() {
  // Health display
  fill(255);
  textSize(20);
  text("Health: " + character.getHealth(), 50, 50);
  
  // Enemy health display
  for (int i = 0; i < enemies.size(); i++) {
    if (!enemies.get(i).isDead) {
      fill(255, 0, 0); // Red for alive enemies
      text("Enemy " + (i+1) + ": " + enemies.get(i).getHealth(), width - 200, 50 + i * 30);
    } else {
      fill(0, 255, 0); // Green for defeated enemies
      text("Enemy " + (i+1) + ": Defeated", width - 200, 50 + i * 30);
    }
  }
  
  // Display enemies defeated counter
  int defeatedCount = 0;
  for (Enemy enemy : enemies) {
    if (enemy.isDead) defeatedCount++;
  }
  
  fill(255, 215, 0); // Gold color
  text("Enemies Defeated: " + defeatedCount + "/" + enemies.size(), width/2 - 100, 50);
  
  // Stopwatch display
  fill(255);
  if (timerRunning) {
    long currentTime = millis();
    long elapsedTime = currentTime - gameStartTime;
    text("Time: " + formatTime(elapsedTime), 50, 80);
  } else if (gameEndTime > 0) {
    // Display final time after victory
    long elapsedTime = gameEndTime - gameStartTime;
    text("Time: " + formatTime(elapsedTime), 50, 80);
  }
  
  // Game over message 
  if (gameOver) {
    displayGameOver();
  }
}

// format milliseconds as mm:ss.ms
String formatTime(long millis) {
  int seconds = (int) (millis / 1000) % 60;
  int minutes = (int) (millis / (1000 * 60));
  int ms = (int) (millis % 1000) / 10; // Show only 2 digits for milliseconds
  
  return String.format("%02d:%02d.%02d", minutes, seconds, ms);
}

void displayStartScreen() {
  fill(0, 0, 0, 150);
  rect(0, 0, width, height);
  
  // Game title
  fill(255);
  textSize(80);
  textAlign(CENTER, CENTER);
  text("OVER S∞∞N", width/2, height/3 - 40);
  
  // Controls section
  textSize(30);
  text("CONTROLS", width/2, height/2 - 60);
  
  textSize(24);
  int yPos = height/2;
  text("A / D - Move left / right", width/2, yPos);
  text("W - Jump", width/2, yPos + 35);
  text("SPACE - Attack", width/2, yPos + 70);
  text("SHIFT - Glide", width/2, yPos + 105);
  
  // Start prompt
  textSize(30);
  fill(255, 255, 0);
  text("Press ENTER to start", width/2, height - 100);
  
  // Reset text alignment
  textAlign(LEFT, BASELINE);
}

void displayGameOver() {
  fill(0, 0, 0, 150);
  rect(0, 0, width, height);
  
  // Check if player died or if they won
  boolean playerDied = character.isDead;
  
  if (playerDied) {
    // Game over text - defeat
    fill(255, 0, 0);
    textSize(80);
    textAlign(CENTER, CENTER);
    text("GAME OVER", width/2, height/2 - 40);
  } else {
    // Victory text - all enemies defeated and coin collected
    fill(255, 215, 0); // Gold color
    textSize(80);
    textAlign(CENTER, CENTER);
    text("VICTORY!", width/2, height/2 - 40);
    
    fill(255);
    textSize(30);
    text("You defeated all enemies and reached the summit!", width/2, height/2 + 10);
    
    // Show the final time
    textSize(24);
    text("Your time: " + formatTime(gameEndTime - gameStartTime), width/2, height/2 + 50);
  }
  
  // Instructions to restart
  fill(255);
  textSize(30);
  text("Press 'R' to restart", width/2, height/2 + 100);
  
  // Reset text alignment
  textAlign(LEFT, BASELINE);
}

void resetGame() {
  // Reset game state
  gameOver = false;
  attackLanded = false;
  
  // Reset timer
  gameStartTime = millis();
  gameEndTime = 0;
  timerRunning = true;
  
  // Clear all collections
  physicsEngine = new PhysicsEngine();
  enemies.clear();
  springs.clear();
  platforms.clear();
  coins.clear();
  
  // Recreate character, enemies, platforms and springs
  character = new Character(new PVector(width / 2, height - 30));
  
  // Recreate enemies with opposite patrol directions
  Enemy enemy1 = new Enemy(new PVector(width / 4, height - 30), character);
  
  Enemy enemy2 = new Enemy(new PVector(width * 3 / 4, height - 30), character);
  
  // Recreate two more enemies on the third layer platforms 
  Enemy enemy3 = new Enemy(new PVector(width * 0.35f, height - 330 - 20), character);
  
  Enemy enemy4 = new Enemy(new PVector(width * 0.65f, height - 330 - 20), character); 
  
  enemies.add(enemy1);
  enemies.add(enemy2);
  enemies.add(enemy3);
  enemies.add(enemy4);

  float platformWidth = 32;

  enemies.get(0).steeringController.clearBehaviors();
  enemies.get(0).steeringController.addBehavior(new Seek(character.position, 0.7), 1.0);

  // Enemy 2: Mix of seeking player and wandering - less predictable hunter
  enemies.get(1).steeringController.clearBehaviors();
  enemies.get(1).steeringController.addBehavior(new Seek(character.position, 0.4), 0.6);
  enemies.get(1).steeringController.addBehavior(new Wander(0.3, 50, 30), 0.4);

  // Enemy 3: Wander on platform
  enemies.get(2).steeringController.clearBehaviors();
  enemies.get(2).steeringController.addBehavior(new Wander(0.3, 70, 40), 0.5);

  // Enemy 4: Wander on platform and flee from player
  enemies.get(3).steeringController.clearBehaviors();
  enemies.get(3).steeringController.addBehavior(new Wander(0.3, 50, 30), 0.4);
  enemies.get(3).steeringController.addBehavior(new Flee(character.position, 0.6, 150), 0.7);

  // Recreate platforms
  platforms.add(new PlatformObject(width * 0.25f - platformWidth, height - 150));
  platforms.add(new PlatformObject(width * 0.25f, height - 150));                 
  platforms.add(new PlatformObject(width * 0.25f + platformWidth, height - 150)); 
  
  platforms.add(new PlatformObject(width * 0.75f - platformWidth, height - 150)); 
  platforms.add(new PlatformObject(width * 0.75f, height - 150));                
  platforms.add(new PlatformObject(width * 0.75f + platformWidth, height - 150)); 
  
  platforms.add(new PlatformObject(width * 0.5f - platformWidth, height - 270)); 
  platforms.add(new PlatformObject(width * 0.5f, height - 270));                
  platforms.add(new PlatformObject(width * 0.5f + platformWidth, height - 270)); 
  
  platforms.add(new PlatformObject(width * 0.35f - platformWidth, height - 330)); 
  platforms.add(new PlatformObject(width * 0.35f, height - 330));                
  platforms.add(new PlatformObject(width * 0.35f + platformWidth, height - 330)); 
  
  platforms.add(new PlatformObject(width * 0.65f - platformWidth, height - 330));
  platforms.add(new PlatformObject(width * 0.65f, height - 330));                 
  platforms.add(new PlatformObject(width * 0.65f + platformWidth, height - 330)); 
  
  platforms.add(new PlatformObject(width * 0.5f - platformWidth, height - 410)); 
  platforms.add(new PlatformObject(width * 0.5f, height - 490));                 
  platforms.add(new PlatformObject(width * 0.5f + platformWidth, height - 410));
  
  // Recreate springs
  springs.add(new Spring(new PVector(width * 0.15f, height - 20)));
  springs.add(new Spring(new PVector(width * 0.85f, height - 20)));
  springs.add(new Spring(new PVector(width * 0.5f, height - 150)));
  
  // Recreate coins
  coins.add(new Coin(new PVector(width * 0.5f, height - 510 - 10))); 
  
  // Add objects to physics engine
  physicsEngine.addObject(character);
  for (Enemy enemy : enemies) {
    physicsEngine.addObject(enemy);
  }
  
  for (Spring spring : springs) {
    physicsEngine.addObject(spring);
  }
  
  for (PlatformObject platform : platforms) {
    physicsEngine.addObject(platform);
  }
  
  // Add force generators
  GravityForce gravity = new GravityForce(1.5f);
  DragForce drag = new DragForce(0.01f);
  
  physicsEngine.addForceGenerator(character, gravity);
  physicsEngine.addForceGenerator(character, drag);
  
  for (Enemy enemy : enemies) {
    physicsEngine.addForceGenerator(enemy, gravity);
    physicsEngine.addForceGenerator(enemy, drag);
  }
}

// Update the updateCoins method to stop the timer when the player wins
void updateCoins() {
  // Update all coins
  for (int i = coins.size() - 1; i >= 0; i--) {
    Coin coin = coins.get(i);
    coin.update();
    
    // Check for collision with player if not already collected
    if (!coin.isCollected() && !gameOver) {
      // distance-based collision check
      float distance = PVector.dist(character.position, coin.position);
      if (distance < character.radius + coin.radius) {
        // Check if all enemies are defeated
        boolean allEnemiesDefeated = true;
        for (Enemy enemy : enemies) {
          if (!enemy.isDead) {
            allEnemiesDefeated = false;
            break;
          }
        }
        
        if (allEnemiesDefeated) {
          // All enemies are defeated, allow coin collection
          coin.collect();
          
          // Stop the timer when the player wins
          if (timerRunning) {
            gameEndTime = millis();
            timerRunning = false;
          }
          
          // Add victory visual effect
          pushStyle();
          fill(255, 255, 0, 100);
          ellipse(coin.position.x, coin.position.y, 200, 200);
          popStyle();
          
          // Set game won state after a short delay to allow animation to play
          Thread coinThread = new Thread(new Runnable() {
            public void run() {
              try {
                // Wait for the coin destroy animation to finish
                Thread.sleep(1000);
                gameOver = true;
              } catch (InterruptedException e) {
                e.printStackTrace();
              }
            }
          });
          coinThread.start();
        } else {
          // Not all enemies defeated, show a message
          pushStyle();
          fill(255, 0, 0, 150);
          textSize(20);
          textAlign(CENTER, CENTER);
          text("Defeat all enemies first!", width/2, height/2 - 100);
          popStyle();
        }
      }
    }
  }
}

