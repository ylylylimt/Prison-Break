// -------------------- GLOBAL VARIABLES --------------------

// Game state flags
boolean showMainMenu = true;
boolean showModeMenu = false;
boolean showInstructions = false;
boolean gameStarted = false;
boolean gamePaused = false;

// Game mode and instructions
String gameMode = "";  
String instructions = "";

// Maze variables
int cols, rows;
int w = 60;
Cell[] grid;
boolean drawFinish = false;

Cell current;
ArrayList<Cell> stack;

// Lighting variables
float lightAreaSize = 200; 
float lighter = 255; 
boolean lighterN = true;
color BGcolour = color (0,0,0);

// Player variables
float px, py; 
float pSize = 15;
boolean aDown = false;
boolean sDown = false;
boolean dDown = false;
boolean wDown = false;

// Game reset and scoring
boolean reset = false;

float score = 0;
float highScore = 0;

// Enemy (guard) variables
int numberOfGuard = 10; 
float[] eX = new float[numberOfGuard];
float[] eY = new float[numberOfGuard];
float[] speedX = new float[numberOfGuard]; 
float[] speedY = new float[numberOfGuard];

// Hard mode toggle
boolean hardMode= false;
int nm = 2;
float nmBonus = 0;

// -------------------- SETUP & MAIN LOOP --------------------

void setup() {
  size(600, 600);
  px = 25;
  py = 25;
  
  strokeWeight(3);
  cols = (int)(width / w);
  rows = (int)(height / w);
  grid = new Cell[cols * rows];
  stack = new ArrayList<Cell>();

  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      grid[i + j * rows] = new Cell(i, j);
    }
  }
  current = grid[0];
  
  buildMaze();
  initEnemies();
}

// -------------------- MENU SCREENS --------------------

void draw() {
  if (showMainMenu) {
    displayMainMenu();
  } else if (showModeMenu) {
    displayModeMenu();
  } else if (showInstructions) {
    displayInstructions();
  } else if (gameStarted) {
    if (!gamePaused) {
      playGame();
    } else {
      displayPauseScreen();
    }
  }
}

void displayMainMenu() {
  background(0);
  textAlign(CENTER);

  textSize(50);
  fill(255,140,0);
  text("Prison Break", width / 2, height / 2 - 100);

  textSize(15);
  fill(255);
  text("Escape prison, armed with a lighter, avoid walls, make your way to exit in bottom right corner.", width / 2, height / 2 - 30);
  text("Watch out for the patrolling policemen – if they catch you, you'll be sent back to start.", width / 2, height / 2);
  text("Can you navigate the darkness, outsmart the guards, and break free?", width / 2, height / 2 + 30);
  
  fill(255,140,0);
  textSize(20);
  text("Press ENTER to continue", width / 2, height / 2 + 100);
}


void displayModeMenu() {
  background(0);
  textAlign(CENTER);
  
  textSize(40);
  fill(255);
  text("Choose Game Mode", width / 2, height / 2 - 100);
  
  textSize(25);
  fill(255,140,0);
  text("Press E for easy mode", width / 2, height / 2 - 30);
  text("Press H for hard mode", width / 2, height / 2 + 30);
}

void displayInstructions() {
  background(0);
  textAlign(CENTER);
  textSize(35);
  fill(255,140,0);
  text("Instructions for " + gameMode + " mode", width / 2, height / 2 - 150);
  textSize(20);
  fill(255);
  text(instructions, width / 2, height / 2 - 80);
  fill(255,140,0);
  if (gamePaused) {
    text("Game Paused", width / 2, height / 2 + 80);
    text("Press P to continue", width / 2, height / 2 + 120);
  } else {
    text("Press ENTER to start", width / 2, height / 2 + 80);
  }
}

void displayPauseScreen() {
  displayInstructions();  
}

// -------------------- MAZE GENERATION --------------------

void buildMaze() {
  while (true) {
    current.visited = true;
    Cell next = current.checkNeighbours();
    if (next != null) {
      next.visited = true;
      stack.add(current);
      removeWalls(current, next);
      current = next;
    } else if (stack.size() > 0) {
      current = stack.remove(stack.size() - 1);
    } else {
      drawFinish = true;
      break;
    }
  }
}

void initEnemies() {
  for (int n = 0; n < numberOfGuard; n++) {
    eX[n] = random(50, 600);
    eY[n] = random(50, 600);
    speedX[n] = random(-1.5, 1.5);
    speedY[n] = random(-1.5, 1.5);
  }
}

// -------------------- GAMEPLAY CORE --------------------

void playGame() {
background(BGcolour);

  if (drawFinish) {
    for (int i = 0; i < grid.length; i++) {
      Cell cell = grid[i];
      float cellCenterX = cell.i * w + w / 2;
      float cellCenterY = cell.j * w + w / 2;
      float distanceToPlayer = dist(px, py, cellCenterX, cellCenterY);

      if (distanceToPlayer < lightAreaSize / 2) {
        cell.show();
      }
    }
  }

  lightArea(px, py, lightAreaSize);
  lighterOn();
  
  exit();
  player(px, py);
  controls();
  guard();
  checkCollision(px, py);
  reset = false;
  score();
  win();
  enableHardMode(hardMode);
}

void removeWalls(Cell a, Cell b) {
  int x = a.i - b.i, y = a.j - b.j;
  if (x == 1) { a.walls[3] = b.walls[1] = false; }
  else if (x == -1) { a.walls[1] = b.walls[3] = false; }
  if (y == 1) { a.walls[0] = b.walls[2] = false; }
  else if (y == -1) { a.walls[2] = b.walls[0] = false; }
}

// -------------------- LIGHT SYSTEM --------------------

void lightArea(float x, float y, float size) {
  noStroke();
  fill(150, lighter);
  circle(x, y, size);
}

void lighterOn() {
  float n = -5;
  if(lighter >= 255) {
    lighterN = true;
  }
  if(lighter <= 0) {
    lighterN = false;
  }
  if(!lighterN) {
    lighter -= n;
  } else if(lighterN) {
    lighter += n;
  }
}

// -------------------- PLAYER --------------------

void player(float x, float y) {
  strokeWeight(2);
  stroke(0);
  fill(255,140,0);

  // face
  ellipse(x, y, pSize, pSize); 
  fill(0); 

  // eyes
  float eyeOffsetX = pSize * 0.15;
  float eyeOffsetY = pSize * -0.1;
  ellipse(x - eyeOffsetX, y + eyeOffsetY, pSize * 0.1, pSize * 0.1);
  ellipse(x + eyeOffsetX, y + eyeOffsetY, pSize * 0.1, pSize * 0.1);

  // smile
  noFill();
  arc(x, y + pSize * 0.1, pSize * 0.5, pSize * 0.3, 0, PI);

  // body
  strokeWeight(1);
  line(x, y + pSize / 2, x, y + pSize); 
  line(x, y + pSize, x - pSize * 0.3, y + pSize * 1.5); 
  line(x, y + pSize, x + pSize * 0.3, y + pSize * 1.5);

  // arms
  line(x, y + pSize * 0.5, x - pSize * 0.4, y + pSize * 0.7); 
  line(x, y + pSize * 0.5, x + pSize * 0.4, y + pSize * 0.7); 
}

// -------------------- GUARD (ENEMY) --------------------

void guard() {
    for(int i = 0; i < numberOfGuard; i++) { 
        eX[i] += speedX[i];
        eY[i] += speedY[i];
        
        if (eX[i] >= width - pSize * 2) speedX[i] *= -1;
        if (eX[i] <= 0 + pSize * 2) speedX[i] *= -1;
        if (eY[i] >= height - pSize * 2) speedY[i] *= -1;
        if (eY[i] <= 0 + pSize * 2) speedY[i] *= -1;

    
        // policeman guard
        fill(0, 0, 255); 
        strokeWeight(2);
        stroke(0);
        ellipse(eX[i], eY[i], pSize, pSize); 
        fill(0);

        // eyes
        float eyeOffsetX = pSize * 0.2;
        float eyeOffsetY = pSize * -0.1;
        ellipse(eX[i] - eyeOffsetX, eY[i] + eyeOffsetY, pSize * 0.1, pSize * 0.1); // Left eye
        ellipse(eX[i] + eyeOffsetX, eY[i] + eyeOffsetY, pSize * 0.1, pSize * 0.1); // Right eye

        // glasses
        noFill();
        arc(eX[i], eY[i] - pSize * 0.1, pSize * 0.5, pSize * 0.3, PI, TWO_PI); 

        // body 
        line(eX[i], eY[i] + pSize / 2, eX[i], eY[i] + pSize); 
        line(eX[i], eY[i] + pSize / 2, eX[i] - pSize * 0.3, eY[i] + pSize * 0.75); // Left arm
        line(eX[i], eY[i] + pSize / 2, eX[i] + pSize * 0.3, eY[i] + pSize * 0.75); // Right arm

        // legs
        line(eX[i], eY[i] + pSize, eX[i] - pSize * 0.3, eY[i] + pSize * 1.5); // Left leg
        line(eX[i], eY[i] + pSize, eX[i] + pSize * 0.3, eY[i] + pSize * 1.5); // Right leg
        
        if (eX[i] < px + pSize * 2 && eY[i] < py + pSize * 2 && eX[i] > px - pSize * 2 && eY[i] > py - pSize * 2) {
            reset = true;
        }
    }
}

void checkCollision(float x, float y) {
  boolean collision = false;
  
  int cellX = (int)(px / w);
  int cellY = (int)(py / w);
  int cellIndex = current.index(cellX, cellY);

  if (cellIndex != -1) {
    Cell cell = grid[cellIndex];

    float r = pSize / 2;
    float left = cellX * w;
    float right = left + w;
    float top = cellY * w;
    float bottom = top + w;

    if (cell.walls[0] && lineCircle(left, top, right, top, x, y, r)) collision = true;    // Top wall
    if (cell.walls[1] && lineCircle(right, top, right, bottom, x, y, r)) collision = true; // Right wall
    if (cell.walls[2] && lineCircle(right, bottom, left, bottom, x, y, r)) collision = true; // Bottom wall
    if (cell.walls[3] && lineCircle(left, bottom, left, top, x, y, r)) collision = true;   // Left wall
  }
  
    if (collision || reset) {
    px = 25;
    py = 25;
    score = 0;
  }
}

// -------------------- SCORING & WIN CONDITION --------------------

boolean win() {
    if (reset) { 
        if ((highScore == 0) || (score < highScore)) {
            highScore = score;
        }
        reset = false; 
        return true;
    }
    return false;
}

void score() {
  textAlign(CENTER, BOTTOM);
  textSize(25);
  fill(255,140,0);
  text("record: "+(int) highScore/60,500,30);
  text("escape time: "+(int) score/60,100,30);
  score = score +(1-nmBonus);
}


void enableHardMode(boolean nmOn) {
  if (nmOn) {
    nm = numberOfGuard;
    nmBonus = 0.5; 
  } else {
    nm = numberOfGuard/2;
    nmBonus = 0;
  }
}  

void controls() {
  float speed = hardMode? 2 : 1;
  if (aDown) px -= speed;
  if (dDown) px += speed;
  if (wDown) py -= speed;
  if (sDown) py += speed;
}

void exit() { 
    if (px > width - 50 && py > height - 50) {
        strokeWeight(6);
        stroke(255);
        fill(255);
        line(width - 100, height, width, height); 
        if (px > width - 75 && py > height - 75) {
            noStroke();
            fill(255, 100);
            beginShape();
            vertex(width - 70, height);
            vertex(width, height);
            vertex(px, py);
            endShape(CLOSE);
        }
        reset = true;
        win();
    }
}

// -------------------- GEOMETRY HELPERS --------------------

boolean lineCircle(float x1, float y1, float x2, float y2, float cx, float cy, float r) {
  boolean inside1 = pointCircle(x1, y1, cx, cy, r);
  boolean inside2 = pointCircle(x2, y2, cx, cy, r);
  if (inside1 || inside2) return true;

  float distX = x1 - x2;
  float distY = y1 - y2;
  float len = sqrt((distX * distX) + (distY * distY));

  float dot = (((cx - x1) * (x2 - x1)) + ((cy - y1) * (y2 - y1))) / pow(len, 2);

  float closestX = x1 + (dot * (x2 - x1));
  float closestY = y1 + (dot * (y2 - y1));

  boolean onSegment = linePoint(x1, y1, x2, y2, closestX, closestY);
  if (!onSegment) return false;

  distX = closestX - cx;
  distY = closestY - cy;
  float distance = sqrt((distX * distX) + (distY * distY));

  return distance <= r;
}

boolean pointCircle(float px, float py, float cx, float cy, float r) {
  float distX = px - cx;
  float distY = py - cy;
  float distance = sqrt((distX * distX) + (distY * distY));
  return distance <= r;
}

boolean linePoint(float x1, float y1, float x2, float y2, float px, float py) {
  float d1 = dist(px, py, x1, y1);
  float d2 = dist(px, py, x2, y2);
  float lineLen = dist(x1, y1, x2, y2);
  float buffer = 0.1;
  return d1 + d2 >= lineLen - buffer && d1 + d2 <= lineLen + buffer;
}

// -------------------- KEY HANDLING --------------------

void keyPressed() {
  if (showMainMenu && key == ENTER) {
    showMainMenu = false;
    showModeMenu = true;
  } 
  else if (showModeMenu) {
    if (key == 'E' || key == 'e') {
      gameMode = "easy";
      instructions = "WSAD/arrow keys for movement\nPress P to pause/continue\nPress Q to quit";
      showModeMenu = false;
      showInstructions = true;
    } else if (key == 'H' || key == 'h') {
      gameMode = "hard";
      instructions = "WSAD/arrow keys for movement\nPress P to pause/continue\nPress R to reset to easy mode\nPress Q to quit";
      showModeMenu = false;
      showInstructions = true;
      hardMode= true;
      px = 25;
      py = 25;
      score = 0;
      for(int n2 = 0; n2 < numberOfGuard; n2 += 1){
        speedX[n2] = random(-3,3);
        speedY[n2] = random(-3,3);
      }
    }
  } 
  else if (showInstructions) {
    if (key == ENTER) {
      showInstructions = false;
      gameStarted = true;
    }
  } 
  else if (gameStarted) {
    if (key == 'P' || key == 'p') {
      gamePaused = !gamePaused;
      showInstructions = false;  
    } else if (key == 'Q' || key == 'q') {
      exit();  
    } 
    else if (key == 'A' || key == 'a' || keyCode == LEFT) { 
      aDown = true;
    }
    else if (key == 'D' || key == 'd' || keyCode == RIGHT) { 
      dDown = true;
    }
    else if (key == 'W' || key == 'w' || keyCode == UP) {
      wDown = true;
    }
    else if (key == 'S' || key == 's' || keyCode == DOWN) {
      sDown = true;
    }
    if(key == 'r' || key == 'R'){
      hardMode= false; 
      reset = true;
    }
  }
}

void keyReleased(){
  if(key == 'A' || key == 'a' || keyCode == LEFT){ 
    aDown = false;
  } 
  else if(key == 'D' || key == 'd' || keyCode == RIGHT){ 
    dDown = false;
  }
  else if(key == 'W' || key =='w' || keyCode == UP) {
    wDown = false;
  }
  else if(key == 'S' || key == 's' || keyCode == DOWN) {
    sDown = false;
  }
}
