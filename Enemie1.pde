class Enemy extends PhysicsObject {
    private PImage[] idleFrames;
    private PImage[] hitFrames;
    private PImage[] attackFrames;
    private PImage[] deathFrames;
    private PImage[] runFrames;
    private float currentFrame = 0.0f;
    private boolean hFlip = false;
    private int health = 100; 
    public boolean isDead = false;
    private boolean isHit = false;
    private boolean isAttacking = false;
    private boolean isRunning = false;
    private Character player; 
    public SteeringController steeringController;
    private boolean isPlatformBound = false;  // Whether enemy is bound to a platform
    private float platformX;                  // Center X of platform
    private float platformWidth;              // Width of platform
    private float platformY;                  // Y position of platform

    
    // Attack collision detection
    private final static int ATTACK_COLLISION_START_FRAME = 4; 
    private final static int ATTACK_COLLISION_END_FRAME = 12;

    public Enemy(PVector start, Character player) {
        super(start, 1.0f); 
        this.player = player;
                
        loadIdleFrames("PixelArt_Samurai/Enemies/Assassin/PNG/WithoutOutline/Assassin_Idle.png");
        loadHitFrames("PixelArt_Samurai/Enemies/Assassin/PNG/WithoutOutline/Assassin_Hit.png");
        loadAttackFrames("PixelArt_Samurai/Enemies/Assassin/PNG/WithoutOutline/Assassin_Attack.png");
        loadDeathFrames("PixelArt_Samurai/Enemies/Assassin/PNG/WithoutOutline/Assassin_Death.png");
        loadRunFrames("PixelArt_Samurai/Enemies/Assassin/PNG/WithoutOutline/Assassin_Run.png");
        
        // Initialize the steering controller
        steeringController = new SteeringController(this);
        
        // Default behavior is to seek the player
        Seek seekPlayer = new Seek(player.position, 0.5);
        steeringController.addBehavior(seekPlayer, 1.0);
    }

    // Frame loading methods (unchanged)
    void loadIdleFrames(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 8; // Number of frames in the sprite sheet
        int frameWidth = spriteSheet.width / frameCount; // Width of each frame
        idleFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            idleFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void loadHitFrames(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 9; 
        int frameWidth = spriteSheet.width / frameCount; 
        hitFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            hitFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void loadDeathFrames(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 19; 
        int frameWidth = spriteSheet.width / frameCount; 
        deathFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            deathFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void loadAttackFrames(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 19; 
        int frameWidth = spriteSheet.width / frameCount; 
        attackFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            attackFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }
    
    void loadRunFrames(String imgPath) {
        PImage spriteSheet = loadImage(imgPath);
        int frameCount = 8; 
        int frameWidth = spriteSheet.width / frameCount;
        runFrames = new PImage[frameCount];

        for (int i = 0; i < frameCount; i++) {
            runFrames[i] = spriteSheet.get(i * frameWidth, 0, frameWidth, spriteSheet.height);
        }
    }

    void takeDamage(int damage) {
        // Apply damage but ensure health doesn't go below 0
        health = max(0, health - damage);
        
        isHit = true;
        currentFrame = 0;
        
        if (health <= 0) {
            isDead = true;
            currentFrame = 0;
        }
    }

    void update() {
        // Process behavior and calculate forces
        updateBehavior();
        
        // handle physics
        super.update();

        // Apply platform constraints if needed
        if (isPlatformBound) {
            handlePlatformConstraints();
        }
    }
    
    void updateBehavior() {
        // First, update target positions for behaviors
        for (int i = 0; i < steeringController.behaviors.size(); i++) {
            SteeringBehavior behavior = steeringController.behaviors.get(i);
            if (behavior instanceof Seek) {
                ((Seek)behavior).targetPosition = player.position;
            } else if (behavior instanceof Flee) {
                ((Flee)behavior).targetPosition = player.position;
            }
        }
        
        // Handle special states first
        if (isDead) {
            // Dead enemies don't move
            currentFrame += 0.2; 
            if (currentFrame >= deathFrames.length) {
                currentFrame = deathFrames.length - 1; 
            }
            return;
        } 
        
        if (isHit) {
            // Hit enemies pause their current behavior
            isAttacking = false;
            currentFrame += 0.2; 
            if (currentFrame >= hitFrames.length) {
                isHit = false;
                currentFrame = 0;
            }
            return;
        }
        
        if (isAttacking) {
            // Handle attacking animation and logic
            if (player.position.x < position.x) {
                hFlip = true;
            } else {
                hFlip = false;
            }
            
            currentFrame += 0.2; 
            
            // Check attack collision
            isInAttackCollisionFrame();
            isInAttackRange(player);
            
            // End attack animation
            if (currentFrame >= attackFrames.length) {
                isAttacking = false;
                isRunning = true;
                currentFrame = 0;
            }
            return;
        }
        
        // Check if player is within attack range
        if (PVector.dist(position, player.position) < 25.0f) {
            isAttacking = true;
            isRunning = false;
            currentFrame = 0;
            return;
        }
        
        // Apply steering behaviors
        steeringController.calculateSteering();
        
        // Update animation state based on movement
        isRunning = velocity.mag() > 0.1;
        
        // Update facing direction based on movement
        if (velocity.x < -0.1) {
            hFlip = true;
        } else if (velocity.x > 0.1) {
            hFlip = false;
        }
        
        // Update animation frames
        if (isRunning) {
            currentFrame += 0.1;
            if (currentFrame >= runFrames.length) {
                currentFrame = 0;
            }
        } else {
            // Idle animation
            currentFrame += 0.1;
            if (currentFrame >= idleFrames.length) {
                currentFrame = 0;
            }
        }
    }

    void draw() {
        PImage frame;
        if (isDead) {
            frame = deathFrames[(int)currentFrame];
        } else if (isHit) {
            frame = hitFrames[(int)currentFrame];
        } else if (isAttacking) {
            frame = attackFrames[(int)currentFrame];
        } else if (isRunning) {
            frame = runFrames[(int)currentFrame];
        } else {
            frame = idleFrames[(int)currentFrame];
        }

        if (hFlip) {
            pushMatrix();
            scale(-1.0, 1.0);
            image(frame, -this.position.x, this.position.y);
            popMatrix();
        } else {
            image(frame, this.position.x, this.position.y);
        }
    }

    public boolean isInAttackRange(Character player) {
        if (player.position.x >= position.x - 30 && player.position.x <= position.x + 30) {
            return true;
        } else {
            return false;
        }
    }

    public boolean isInAttackCollisionFrame() {
        if (currentFrame >= ATTACK_COLLISION_START_FRAME && currentFrame <= ATTACK_COLLISION_END_FRAME) {
            return true;
        } else {
            return false;
        }
    }

    public boolean isAttacking() {
        return isAttacking;
    }

    // get health
    public int getHealth() {
        return health;
    }

}