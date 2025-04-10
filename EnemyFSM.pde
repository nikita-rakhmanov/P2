// Define possible enemy states
enum EnemyState {
  IDLE,
  PATROL,
  CHASE,
  ATTACK,
  HIT,
  DEAD
}

class EnemyFSM {
  private Enemy owner;
  private EnemyState currentState;
  private HashMap<EnemyState, EnemyStateHandler> stateHandlers;
  
  EnemyFSM(Enemy owner) {
    this.owner = owner;
    this.currentState = EnemyState.IDLE;
    
    // Initialize state handlers
    stateHandlers = new HashMap<EnemyState, EnemyStateHandler>();
    stateHandlers.put(EnemyState.IDLE, new IdleStateHandler(this));
    stateHandlers.put(EnemyState.PATROL, new PatrolStateHandler(this));
    stateHandlers.put(EnemyState.CHASE, new ChaseStateHandler(this));
    stateHandlers.put(EnemyState.ATTACK, new AttackStateHandler(this));
    stateHandlers.put(EnemyState.HIT, new HitStateHandler(this));
    stateHandlers.put(EnemyState.DEAD, new DeadStateHandler(this));
  }
  
  void update() {
    // Get the current state handler and update
    EnemyStateHandler currentHandler = stateHandlers.get(currentState);
    currentHandler.update();
    
    // Check for state transitions
    checkStateTransitions();
  }
  
  void checkStateTransitions() {
    // This method will check conditions and potentially change states
    EnemyStateHandler currentHandler = stateHandlers.get(currentState);
    EnemyState nextState = currentHandler.checkTransitions();
    
    if (nextState != currentState) {
      // State change
      EnemyStateHandler oldHandler = stateHandlers.get(currentState);
      EnemyStateHandler newHandler = stateHandlers.get(nextState);
      
      // Exit old state
      oldHandler.exit();
      
      // Change state
      currentState = nextState;
      
      // Enter new state
      newHandler.enter();
      
      // Debug message
      println("Enemy state changed from " + currentState + " to " + nextState);
    }
  }
  
  void forceState(EnemyState newState) {
    if (newState != currentState) {
      // Exit current state
      stateHandlers.get(currentState).exit();
      
      // Change state
      currentState = newState;
      
      // Enter new state
      stateHandlers.get(currentState).enter();
      
      println("Enemy state forced to " + newState);
    }
  }
  
  Enemy getOwner() {
    return owner;
  }
  
  EnemyState getCurrentState() {
    return currentState;
  }
}

// Base interface for state handlers
interface EnemyStateHandler {
  void enter();  // Called when entering the state
  void update(); // Called every frame while in this state
  void exit();   // Called when exiting the state
  EnemyState checkTransitions(); // Check if should transition to a new state
}

// Implementations for each state
class IdleStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  private float idleTimer;
  private final float IDLE_DURATION = 2.0f; // seconds
  
  IdleStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
    this.idleTimer = 0;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    // Clear all behaviors
    enemy.steeringController.clearBehaviors();
    // Reset animation state
    enemy.isRunning = false;
    enemy.isAttacking = false;
    idleTimer = 0;
  }
  
  void update() {
    // Increment idle timer
    idleTimer += 1.0f / frameRate;
  }
  
  void exit() {
    // Nothing to clean up
  }
  
  EnemyState checkTransitions() {
    Enemy enemy = fsm.getOwner();
    Character player = enemy.player;
    
    // Check if enemy should transition to another state
    if (enemy.isDead) {
      return EnemyState.DEAD;
    } else if (enemy.isHit) {
      return EnemyState.HIT;
    }
    
    // Check if player is within detection range
    float detectionRange = 200.0f;
    float distToPlayer = PVector.dist(enemy.position, player.position);
    
    if (distToPlayer < detectionRange) {
      return EnemyState.CHASE; // Player detected, start chasing
    } else if (idleTimer > IDLE_DURATION) {
      return EnemyState.PATROL; // Idle time exceeded, start patrolling
    }
    
    return EnemyState.IDLE; // Stay idle
  }
}

class PatrolStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  private PVector patrolStart;
  private PVector patrolEnd;
  private float patrolWidth = 150.0f;
  
  PatrolStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    enemy.steeringController.clearBehaviors();
    
    // Customize patrol behavior based on enemy type
    switch(enemy.getEnemyType()) {
      case 1: // Aggressive - small patrol area, faster movement
        patrolWidth = 100.0f;
        break;
      case 2: // Mixed - medium area
        patrolWidth = 150.0f;
        break;
      case 3: // Platform enemy - stays in place more
        patrolWidth = 80.0f;
        break;
      case 4: // Evasive - large patrol area
        patrolWidth = 100.0f;
        // Add flee behavior to move away from player even during patrol
        enemy.steeringController.addBehavior(new Flee(enemy.player.position, 1.2f, 200), 0.8f);
        break;
    }
    
    // Set up patrol area around current position
    patrolStart = new PVector(enemy.position.x - patrolWidth/2, enemy.position.y);
    patrolEnd = new PVector(enemy.position.x + patrolWidth/2, enemy.position.y);
    
    // Add wander behavior for patrolling - increased force for more noticeable movement
    enemy.steeringController.addBehavior(
      new BoundedWander(0.3f, 30, 15, 
                       patrolStart.x, 
                       patrolEnd.x, 
                       enemy.position.y), 1.0f);
    
    // Add a small random force to get movement started
    enemy.applyForce(new PVector(random(-0.5f, 0.5f), 0));
    
    enemy.isRunning = true;
  }
  
  void update() {
    // Calculate steering forces for patrol
    Enemy enemy = fsm.getOwner();
    
    // Update the target position for any Flee behaviors
    for (int i = 0; i < enemy.steeringController.behaviors.size(); i++) {
      SteeringBehavior behavior = enemy.steeringController.behaviors.get(i);
      if (behavior instanceof Flee) {
        ((Flee)behavior).targetPosition = enemy.player.position;
      }
    }
    
    enemy.steeringController.calculateSteering();
  }
  
  void exit() {
    // Nothing specific to clean up
  }
  
  EnemyState checkTransitions() {
    Enemy enemy = fsm.getOwner();
    Character player = enemy.player;
    
    if (enemy.isDead) {
      return EnemyState.DEAD;
    } else if (enemy.isHit) {
      return EnemyState.HIT;
    }
    
    float chaseRange = 150.0f;
    float distToPlayer = PVector.dist(enemy.position, player.position);
    
    if (distToPlayer < chaseRange) {
      return EnemyState.CHASE;
    }
    
    return EnemyState.PATROL; // Stay in patrol
  }
}

class ChaseStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  
  ChaseStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    enemy.steeringController.clearBehaviors();
    
    // Customize chase behavior based on enemy type
    float acceleration = 0.9f;
    float weight = 1.0f;
    
    // Enemy type specific behaviors
    switch(enemy.getEnemyType()) {
      case 1: // Aggressive chaser
        acceleration = 1.2f; // Faster
        weight = 1.0f;
        break;
      case 2: // Mixed behavior
        acceleration = 0.7f; // Medium speed
        weight = 0.8f;
        // Add some wandering to make movement less predictable
        enemy.steeringController.addBehavior(new Wander(0.3f, 50, 30), 0.2f);
        break;
      case 3: // Platform enemy, more cautious
        acceleration = 0.5f; // Slower
        weight = 0.6f;
        break;
      case 4: // Evasive enemy
        acceleration = 0.6f;
        weight = 0.4f;
        // This enemy prefers to keep distance
        enemy.steeringController.addBehavior(new Flee(enemy.player.position, 1f, 100), 0.6f);
        break;
    }
    
    // Add seek behavior to chase player
    enemy.steeringController.addBehavior(
      new Seek(enemy.player.position, acceleration), weight);
    
    // Add a small initial force in the player's direction to kickstart movement
    PVector direction = PVector.sub(enemy.player.position, enemy.position).normalize();
    enemy.applyForce(PVector.mult(direction, 0.5f));
    
    enemy.isRunning = true;
  }
  
  void update() {
    Enemy enemy = fsm.getOwner();
    
    // Update the target position for the seek behavior
    for (int i = 0; i < enemy.steeringController.behaviors.size(); i++) {
      SteeringBehavior behavior = enemy.steeringController.behaviors.get(i);
      if (behavior instanceof Seek) {
        ((Seek)behavior).targetPosition = enemy.player.position;
      }
      else if (behavior instanceof Flee) {
        ((Flee)behavior).targetPosition = enemy.player.position;
      }
    }
    
    // Calculate steering forces to apply movement
    enemy.steeringController.calculateSteering();
  }
  
  void exit() {
    // Nothing specific to clean up
  }
  
  EnemyState checkTransitions() {
    Enemy enemy = fsm.getOwner();
    Character player = enemy.player;
    
    if (enemy.isDead) {
      return EnemyState.DEAD;
    } else if (enemy.isHit) {
      return EnemyState.HIT;
    }
    
    // Customize ranges based on enemy type
    float attackRange = 25.0f;
    float giveUpRange = 250.0f;
    
    switch(enemy.getEnemyType()) {
      case 1: // Aggressive - never gives up, attacks from further
        attackRange = 35.0f;
        giveUpRange = 400.0f;
        break;
      case 2: // Mixed - standard values
        attackRange = 25.0f;
        giveUpRange = 250.0f;
        break;
      case 3: // Platform enemy - more hesitant to attack
        attackRange = 20.0f;
        giveUpRange = 200.0f;
        break;
      case 4: // Evasive - prefers to keep distance, gives up chase easily
        attackRange = 20.0f;
        giveUpRange = 180.0f;
        break;
    }
    
    float distToPlayer = PVector.dist(enemy.position, player.position);
    
    if (distToPlayer < attackRange) {
      return EnemyState.ATTACK;
    } else if (distToPlayer > giveUpRange) {
      return EnemyState.PATROL; // Lost the player, go back to patrol
    }
    
    return EnemyState.CHASE; // Continue chasing
  }
}

class AttackStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  
  AttackStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    enemy.steeringController.clearBehaviors();
    enemy.isAttacking = true;
    enemy.currentFrame = 0;
    
    // Make enemy face the player
    if (enemy.player.position.x < enemy.position.x) {
      enemy.hFlip = true;
    } else {
      enemy.hFlip = false;
    }
  }
  
  void update() {
    // Attack animation and logic is already handled in the Enemy class
  }
  
  void exit() {
    Enemy enemy = fsm.getOwner();
    enemy.isAttacking = false;
  }
  
  EnemyState checkTransitions() {
    Enemy enemy = fsm.getOwner();
    
    if (enemy.isDead) {
      return EnemyState.DEAD;
    } else if (enemy.isHit) {
      return EnemyState.HIT;
    }
    
    // Transition after attack animation is complete
    if (enemy.currentFrame >= enemy.attackFrames.length - 1) {
      // Attack finished, check distance to player
      float attackRange = 25.0f;
      float distToPlayer = PVector.dist(enemy.position, enemy.player.position);
      
      if (distToPlayer < attackRange) {
        // Still in range, attack again
        return EnemyState.ATTACK;
      } else {
        // Out of range, chase
        return EnemyState.CHASE;
      }
    }
    
    return EnemyState.ATTACK; // Continue attacking
  }
}

class HitStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  
  HitStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    enemy.steeringController.clearBehaviors();
    enemy.currentFrame = 0;
    // Hit animation is already handled in the Enemy class
  }
  
  void update() {
    // Hit reaction is handled by the Enemy class
  }
  
  void exit() {
    Enemy enemy = fsm.getOwner();
    enemy.isHit = false;
  }
  
  EnemyState checkTransitions() {
    Enemy enemy = fsm.getOwner();
    
    if (enemy.isDead) {
      return EnemyState.DEAD;
    }
    
    // Transition after hit animation is complete
    if (enemy.currentFrame >= enemy.hitFrames.length - 1) {
      // Hit reaction finished, decide next state
      float attackRange = 25.0f;
      float distToPlayer = PVector.dist(enemy.position, enemy.player.position);
      
      if (distToPlayer < attackRange) {
        return EnemyState.ATTACK;
      } else {
        return EnemyState.CHASE;
      }
    }
    
    return EnemyState.HIT; // Continue hit reaction
  }
}

class DeadStateHandler implements EnemyStateHandler {
  private EnemyFSM fsm;
  
  DeadStateHandler(EnemyFSM fsm) {
    this.fsm = fsm;
  }
  
  void enter() {
    Enemy enemy = fsm.getOwner();
    enemy.steeringController.clearBehaviors();
    enemy.currentFrame = 0;
    // Death animation is handled by the Enemy class
  }
  
  void update() {
    // Death animation and logic is handled by the Enemy class
  }
  
  void exit() {
    // Enemy shouldn't exit the dead state
  }
  
  EnemyState checkTransitions() {
    // No transitions from dead state
    return EnemyState.DEAD;
  }
}