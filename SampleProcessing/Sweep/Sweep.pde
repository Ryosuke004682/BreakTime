ArrayList<Point> points = new ArrayList<Point>();
ArrayList<Mover> movers = new ArrayList<Mover>();
int moverCount = 4;
int margin = 0;
float minReturnRate = 0.02;
float maxReturnRate = 0.1;
float magSqFudge = 10000.0;
float pivotDivisor = 10.0;
float moveMagLimit = 10.0;
float moverMinSpeed = 2.0;
float moverMaxSpeed = 8.0;
float minLerpSpeed = 0.01;
float maxLerpSpeed = 0.2;
boolean randomizeReturnRate = false;
boolean randomizeInitPositions = false;
boolean copperColor = true;
color copper = color(255, 175, 125, 225);
color iceBlue = color(100, 150, 255, 175);

PGraphics pg;

void setup() {
  size(900, 900, P3D);
  pg = createGraphics(1080, 1080, P3D);
  pg.smooth(8);
  pg.beginDraw();
  pg.ellipseMode(RADIUS);
  pg.blendMode(ADD);
  pg.stroke(copperColor ? copper : iceBlue);
  pg.endDraw();
  initPositions(randomizeInitPositions);
  for (int i = 0; i < moverCount; i++) {
    Mover m = new Mover(randomPos());
    movers.add(m);
  }
  
}

void initPositions(boolean randomize) {
  int side = 175;
  float inc = (1.0 * pg.width - margin * 2) / side;
  float r = inc / 2.0;
  points = new ArrayList<Point>();
  for (int i = 0; i < side; i++) {
    float y = margin + i * inc + r;
    for (int j = 0; j < side; j++) {
      float x = margin + j * inc + r;
        PVector o = randomize 
          ? new PVector(random(margin, pg.width - margin), random(margin, pg.height - margin))
          : new PVector(x, y);
        points.add(new Point(o, margin, pg.width - margin, margin, pg.height - margin));
    }
  }
}
boolean save = false;

void draw() {
  pg.beginDraw();
  pg.background(0);
  pg.strokeWeight(1);
  for (Mover m : movers) {
    m.move();
  }
  for (Point p : points) {
    p.update();
    p.show();
  }
  if (save) {
    save = false;
    pg.save("FilamentSweep" + frameCount + ".png");
  }
  pg.endDraw();
  image(pg, 0, 0, width, height);
  if (frameCount % 60 == 0) {
    println(frameCount / 60 + " --- " + frameRate);
  }
}

void mouseClicked() {
  if (mouseButton == LEFT) {
    save = true;
  } 
}

void keyPressed() {
  if (key == CODED && keyCode == UP) {
    randomizeReturnRate = !randomizeReturnRate;
    randomizeInitPositions = !randomizeInitPositions;
    copperColor = !copperColor;
    initPositions(randomizeInitPositions);
    pg.stroke(copperColor ? copper : iceBlue);
  }
}

PVector randomPos() {
  return new PVector(random(pg.width), random(pg.height));
}

class Point {
  
  PVector init, pivot, pos;
  float xMin, xMax, yMin, yMax;
  float returnRate;
  
  Point(PVector pos, float xMin, float xMax, float yMin, float yMax) {
    this.pos = pos;
    this.init = pos.copy();
    this.pivot = pos.copy();
    this.xMin = xMin;
    this.xMax = xMax;
    this.yMin = yMin;
    this.yMax = yMax;
    this.returnRate = randomizeReturnRate ? random(minReturnRate, maxReturnRate) : minReturnRate;
  }
  
  void update() {
    for (Mover m : movers) {
      PVector mover = new PVector(m.pos.x, m.pos.y);
      PVector diff = pos.copy().sub(mover);
      float magSq = diff.magSq();
      PVector n = diff.copy().normalize();
      n.mult(magSqFudge / magSq).limit(moveMagLimit);
      pos.add(n);
      pivot.add(n.div(pivotDivisor));
    }
    pos = PVector.lerp(pos, init, returnRate);
    pivot = PVector.lerp(pivot, init, returnRate);
  }
  
  void checkBounds() {
    if (pos.x < xMin) {
      pos.x = xMin;
    }
    if (pos.x > xMax) {
      pos.x = xMax;
    }
    if (pos.y < yMin) {
      pos.y = yMin;
    }
    if (pos.y > yMax) {
      pos.y = yMax;
    }
  }
  
  void show() {
    pg.line(pivot.x, pivot.y, pos.x, pos.y);
  }
}

class Mover {
  
  PVector pos, dest, vel;
  PVector lerpSpeed;
  
  Mover(PVector pos) {
    this.pos = pos;
    this.dest = randomPos();
    //目的地と現在の位置の差を求め、それを正規化（長さを1に）し、ランダムな速度スケールで掛けてvelに設定
    this.vel = dest.copy().sub(pos).normalize().mult(random(moverMinSpeed, moverMaxSpeed));
    //線形補間速度をランダムな値で設定。
    lerpSpeed = new PVector(random(minLerpSpeed, maxLerpSpeed), random(minLerpSpeed, maxLerpSpeed));
  }
  
  void move() {
    pos.add(vel);
    //目的地に近づきすぎた場合、新しい目的地をランダムで設定して、速度ベクトルを線形補完速度を再計算。
    if (pos.copy().sub(dest).magSq() < vel.magSq()) {
      dest = randomPos();
      vel = dest.copy().sub(pos).normalize().mult(random(moverMinSpeed, moverMaxSpeed));
      lerpSpeed = new PVector(random(minLerpSpeed, maxLerpSpeed), random(minLerpSpeed, maxLerpSpeed));
    }
  }
  
}
