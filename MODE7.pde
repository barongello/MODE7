int worldWidth = 320;
int worldHeight = 240;
int worldPixelSize = 4;
int[] world = new int[worldWidth * worldHeight];
int selectedSprite = 0;
PImage[] sprites = new PImage[6];

int gridSize = 32;
int gridBackground = color(0, 0, 0, 255);
int gridVertical = color(0, 0, 255, 255);
int gridHorizontal = color(255, 0, 255, 255);
int spriteSize = 1024;
PImage sprite = null;

PVector position = new PVector(935, 645); // Position in the world
float angle = 3.0 * PI / 2.0;                // Angle looking at
float nearFrustum = 0.1f;             // Near frustum
float farFrustum = 30.0f;             // Far frustum
float fov = PI * 0.5f;                // 90 degrees
float fovHalf = fov * 0.5f;           // Half fov

float previousTiming = 0;

void resetWorld() {
  for(int i = 0; i < worldWidth * worldHeight; i++) {
    world[i] = color(0, 255, 255, 255);
  }
}

void drawWorld() {
  for(int y = 0; y < worldHeight; y++) {
    for(int x = 0; x < worldWidth; x++) {
      int index = y * worldWidth + x;
      int col = world[index];

      fill(col);

      rect(x * worldPixelSize, y * worldPixelSize, worldPixelSize, worldPixelSize);
    }
  }
}

void createView() {
  if (sprite == null) {
    return;
  }

  // Calculate frustum points
  PVector farLeft = new PVector(
    position.x + cos(angle - fovHalf) * farFrustum,
    position.y + sin(angle - fovHalf) * farFrustum
  );

  PVector farRight = new PVector(
    position.x + cos(angle + fovHalf) * farFrustum,
    position.y + sin(angle + fovHalf) * farFrustum
  );

  PVector nearLeft = new PVector(
    position.x + cos(angle - fovHalf) * nearFrustum,
    position.y + sin(angle - fovHalf) * nearFrustum
  );

  PVector nearRight = new PVector(
    position.x + cos(angle + fovHalf) * nearFrustum,
    position.y + sin(angle + fovHalf) * nearFrustum
  );
  
  stroke(255);
  strokeWeight(3);
  beginShape();
  vertex(farLeft.x, farLeft.y);
  vertex(nearLeft.x, nearLeft.y);
  vertex(nearRight.x, nearRight.y);
  vertex(farRight.x, farRight.y);
  endShape(CLOSE);
  noStroke();

  // Run on half the screen height
  int halfHeight = floor(worldHeight * 0.5f);

  for (int y = 0; y < halfHeight; y++) {
    float sampleDepth = float(y) / halfHeight;

    PVector start = new PVector(
      (farLeft.x - nearLeft.x) / sampleDepth + nearLeft.x,
      (farLeft.y - nearLeft.y) / sampleDepth + nearLeft.y
    );

    PVector end = new PVector(
      (farRight.x - nearRight.x) / sampleDepth + nearRight.x,
      (farRight.y - nearRight.y) / sampleDepth + nearRight.y
    );

    for (int x = 0; x < worldWidth; x++) {
      float sampleWidth = float(x) / worldWidth;

      PVector sample = new PVector(
        (end.x - start.x) * sampleWidth + start.x,
        (end.y - start.y) * sampleWidth + start.y
      );

      int sampleColor = spriteReadColor(floor(sample.x), floor(sample.y));

      int index = (y + halfHeight) * worldWidth + x;

      world[index] = sampleColor;
    }
  }
}

int spriteReadColor(int x, int y) {
  PImage spr = null;
  
  if(sprites.length > 0 && selectedSprite >= 0 && selectedSprite < sprites.length) {
    spr = sprites[selectedSprite];
  }

  if(spr == null) {
    return color(0, 0, 0, 0);
  }
  
  x %= spr.width;
  y %= spr.height;
  
  while(x < 0) {
    x += spr.width;
  }
  
  while(y < 0) {
    y += spr.height;
  }

  return spr.get(x, y);
}

void spriteWriteColor(int x, int y, int col) {
  if (sprite == null) {
    return;
  }

  if (x < 0 || x >= sprite.width) {
    return;
  }

  if (y < 0 || y >= sprite.height) {
    return;
  }

  sprite.set(x, y, col);
}

void createSprite() {
  if(sprite == null) {
    sprite = createImage(spriteSize, spriteSize, ARGB);
  }
  
  sprite.loadPixels();

  for (int y = 0; y < sprite.height; y++) {
    for (int x = 0; x < sprite.width; x++) {
      boolean horizontal = ((y - 1) % gridSize == 0) || (y % gridSize == 0) || ((y + 1) % gridSize == 0);
      boolean vertical = ((x - 1) % gridSize == 0) || (x % gridSize == 0) || ((x + 1) % gridSize == 0);

      if (horizontal) {
        spriteWriteColor(x, y - 1, gridHorizontal);
        spriteWriteColor(x, y + 0, gridHorizontal);
        spriteWriteColor(x, y + 1, gridHorizontal);
      }
      else if (vertical) {
        spriteWriteColor(x - 1, y, gridVertical);
        spriteWriteColor(x + 0, y, gridVertical);
        spriteWriteColor(x + 1, y, gridVertical);
      }
      else {
        spriteWriteColor(x, y, gridBackground);
      }
    }
  }
  
  sprite.updatePixels();
}

void setup() {
  createSprite();

  sprites[0] = sprite;
  sprites[1] = loadImage("mariocircuit-1.png");
  sprites[2] = loadImage("donutplains-1.png");
  sprites[3] = loadImage("ghostvalley-1.png");
  sprites[4] = loadImage("bowsercastle-1.png");
  sprites[5] = loadImage("mariocircuit-2.png");
  
  selectedSprite = 0;

  size(1280, 960);
  
  noStroke();
  
  previousTiming = millis();
}

void draw() {
  int currentTiming = millis();
  float elapsedTime = (currentTiming - previousTiming) / 1000;
  
  previousTiming = currentTiming;

  background(0);
  
  if(keyPressed) {
    switch (key) {
      case 'a': // A
        angle -= 1.0 * elapsedTime;
        break;
      case 'd': // D
        angle += 1.0 * elapsedTime;
        break;
      case 'w': // W
        position.add(PVector.fromAngle(angle).setMag(200 * elapsedTime));
        break;
      case 's': // S
        position.sub(PVector.fromAngle(angle).setMag(200 * elapsedTime));
        break;
      case 'y': // Y
        nearFrustum += 10.0 * elapsedTime;
        break;
      case 'h': // H
        nearFrustum -= 10.0 * elapsedTime;
        break;
      case 'u': // U
        farFrustum += 10.0 * elapsedTime;
        break;
      case 'j': // J
        farFrustum -= 10.0 * elapsedTime;
        break;
      case 'i': // I
        fov += 0.2 * elapsedTime;
        fovHalf += 0.1 * elapsedTime;
        break;
      case 'k': // K
        fov -= 0.2 * elapsedTime;
        fovHalf -= 0.1 * elapsedTime;
        break;
      case 'o': // O
        selectedSprite = (selectedSprite + 1) % sprites.length;
        break;
      case 'l': // L
        selectedSprite = (selectedSprite == 0 ? sprites.length - 1 : selectedSprite - 1);
        break;
    }
    
    println("Position:", position.x, position.y, "Angle:", angle / PI * 180);
    println("Far:", farFrustum, "Near:", nearFrustum, "Fov:", fov / PI * 180);
  }
  
  resetWorld();
  
  createView();
  
  drawWorld();
}
