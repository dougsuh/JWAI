import java.util.ArrayList;

int shift = 12;
int N = 4;
int rowCount = 10;

float topBoxW = 130;
float topBoxH = 44;
float bottomBoxW = 130;
float bottomBoxH = 44;
float markerSize = 18;

boolean[][] rung;
int[] resultForTeam;
ArrayList<PVector> animPath;
float animProgress = 0;
boolean isAnimating = false;
int activeTeam = -1;
boolean waitingForTeamCount = true;
String teamCountInput = "2";
boolean teamCountInputDirty = false;

float leftX;
float rightX;
float ladderTop;
float ladderBottom;

void setup() {
  size(1800, 600);
  smooth();
  textAlign(CENTER, CENTER);

  animPath = new ArrayList<PVector>();
  noLoop();
}

void draw() {
  background(0, 255, 255);
  if (waitingForTeamCount) {
    drawStartScreen();
    return;
  }

  drawFrame();
  drawRails();
  drawRungs();
  drawLabels();
  drawSummary();
  drawAnimation();
  updateAnimation();
}

void initGame(int teamCount) {
  N = teamCount;
  if (N < 2) N = 2;
  if (N > 20) N = 20;
  rung = new boolean[rowCount][N - 1];
  resultForTeam = new int[N];
  animPath.clear();
  animProgress = 0;
  isAnimating = false;
  activeTeam = -1;
  waitingForTeamCount = false;

  float usable = width * 0.62;
  float boxWidth = usable / N * 0.85;
  topBoxW = constrain(boxWidth, 40, 130);
  bottomBoxW = topBoxW;
  topBoxH = 44;
  bottomBoxH = 44;
  markerSize = constrain(18 - (N - 4) * 0.4, 10, 18);

  generateLadder();
  computeResults();
  redraw();
}

void generateLadder() {
  for (int row = 0; row < rowCount; row++) {
    for (int col = 0; col < N - 1; col++) {
      rung[row][col] = false;
    }
  }

  for (int row = 0; row < rowCount; row++) {
    int col = 0;
    while (col < N - 1) {
      if (random(1) < 0.35) {
        rung[row][col] = true;
        col += 2;
      } else {
        col++;
      }
    }
  }
}

void computeResults() {
  for (int team = 0; team < N; team++) {
    int pos = team;
    for (int row = 0; row < rowCount; row++) {
      if (pos < N - 1 && rung[row][pos]) {
        pos++;
      } else if (pos > 0 && rung[row][pos - 1]) {
        pos--;
      }
    }
    resultForTeam[team] = pos;
  }
}

float railX(int index) {
  return map(index, 0, N - 1, width * 0.15, width * 0.85);
}

void drawStartScreen() {
  fill(255);
  textSize(36);
  text("Ladder Shift", width / 2, 110);

  textSize(20);
  fill(0);
  text("Enter number of teams and press Enter", width / 2, 190);

  fill(255);
  stroke(0);
  strokeWeight(2);
  rectMode(CENTER);
  rect(width / 2, 290, 260, 70, 14);

  fill(180, 0, 0);
  textSize(30);
  text(teamCountInput, width / 2, 290);

  fill(0);
  textSize(16);
  text("Allowed range: 2 to 20", width / 2, 370);
}

void drawFrame() {
  leftX = railX(0);
  rightX = railX(N - 1);
  ladderTop = 160;
  ladderBottom = height - 160;

  noStroke();
  fill(0, 40);
  rectMode(CORNER);
  rect(leftX - 80, ladderTop - 50, (rightX - leftX) + 160, (ladderBottom - ladderTop) + 100, 18);

  fill(255);
  textSize(34);
  text("Ladder Shift", width / 2, 48);
  textSize(18);
  text("Click a Team box to animate the connection", width / 2, 84);
  textSize(14);
  text("Press R to reshuffle", width / 2, height - 26);
}

void drawRails() {
  stroke(255);
  strokeWeight(4);
  for (int i = 0; i < N; i++) {
    float x = railX(i);
    line(x, ladderTop, x, ladderBottom);
  }
}

void drawRungs() {
  stroke(255, 120, 0);
  strokeWeight(6);
  float rowStep = (ladderBottom - ladderTop) / (rowCount - 1.0);

  for (int row = 0; row < rowCount; row++) {
    float y = ladderTop + row * rowStep;
    for (int col = 0; col < N - 1; col++) {
      if (rung[row][col]) {
        line(railX(col), y, railX(col + 1), y);
      }
    }
  }
}

void drawLabels() {
  rectMode(CENTER);
  float labelSize = 24;
  if (N > 10) labelSize = 14;
  else if (N > 6) labelSize = 18;
  textSize(labelSize);

  for (int i = 0; i < N; i++) {
    float x = railX(i);

    stroke(0);
    strokeWeight(2);
    if (i == activeTeam) fill(255, 240, 140);
    else fill(255);
    rect(x, ladderTop - 48, topBoxW, topBoxH, 10);
    fill(0, 0, 180);
    text("Team " + (i + 1), x, ladderTop - 48);

    if (isAnimating && activeTeam == i && animProgress >= 1.0) fill(220, 255, 220);
    else fill(255);
    rect(x, ladderBottom + 48, bottomBoxW, bottomBoxH, 10);
    fill(180, 0, 0);
    text(shift + i + 1, x, ladderBottom + 48);
  }
}

void drawSummary() {
  textAlign(LEFT, TOP);
  textSize(N > 10 ? 14 : 20);
  fill(0);
  noStroke();

  float x = width * 0.73;
  float y = 140;
  text("Result map", x, y);
  y += 34;

  for (int team = 0; team < N; team++) {
    int finalPos = resultForTeam[team];
    text("Team " + (team + 1) + " -> " + (shift + finalPos + 1), x, y);
    y += 30;
  }
}

void drawAnimation() {
  if (animPath.size() < 2 || activeTeam < 0) {
    return;
  }

  drawPolyline(animPath, 1.0, color(0, 0, 0, 50), 6);
  drawPolyline(animPath, animProgress, color(255, 40, 40), 8);

  PVector marker = getPointAtProgress(animPath, animProgress);
  noStroke();
  fill(255, 40, 40);
  ellipse(marker.x, marker.y, markerSize, markerSize);

  if (animProgress >= 1.0) {
    textAlign(LEFT, TOP);
    fill(0);
    textSize(22);
    text("Team " + (activeTeam + 1) + " connects to " + (shift + resultForTeam[activeTeam] + 1), width * 0.55, 108);
  }
}

void drawPolyline(ArrayList<PVector> points, float progress, int c, float weight) {
  stroke(c);
  strokeWeight(weight);
  noFill();

  float totalLen = pathLength(points);
  float targetLen = totalLen * constrain(progress, 0, 1);
  float drawnLen = 0;

  PVector prev = points.get(0);
  beginShape();
  vertex(prev.x, prev.y);

  for (int i = 1; i < points.size(); i++) {
    PVector next = points.get(i);
    float segLen = PVector.dist(prev, next);

    if (drawnLen + segLen <= targetLen) {
      vertex(next.x, next.y);
      drawnLen += segLen;
      prev = next;
    } else {
      float remain = targetLen - drawnLen;
      if (segLen > 0) {
        float t = constrain(remain / segLen, 0, 1);
        vertex(lerp(prev.x, next.x, t), lerp(prev.y, next.y, t));
      }
      break;
    }
  }

  endShape();
}

float pathLength(ArrayList<PVector> points) {
  float total = 0;
  for (int i = 0; i < points.size() - 1; i++) {
    total += PVector.dist(points.get(i), points.get(i + 1));
  }
  return total;
}

PVector getPointAtProgress(ArrayList<PVector> points, float progress) {
  if (points.size() == 0) {
    return new PVector(width / 2, height / 2);
  }
  if (points.size() == 1) {
    return points.get(0).copy();
  }

  float totalLen = pathLength(points);
  float targetLen = totalLen * constrain(progress, 0, 1);
  float drawnLen = 0;

  for (int i = 0; i < points.size() - 1; i++) {
    PVector a = points.get(i);
    PVector b = points.get(i + 1);
    float segLen = PVector.dist(a, b);

    if (drawnLen + segLen >= targetLen) {
      float t = segLen == 0 ? 0 : constrain((targetLen - drawnLen) / segLen, 0, 1);
      return new PVector(lerp(a.x, b.x, t), lerp(a.y, b.y, t));
    }

    drawnLen += segLen;
  }

  return points.get(points.size() - 1).copy();
}

void updateAnimation() {
  if (!isAnimating) {
    return;
  }

  animProgress += 0.02;
  if (animProgress >= 1.0) {
    animProgress = 1.0;
    isAnimating = false;
    noLoop();
  } else {
    redraw();
  }
}

void mousePressed() {
  if (waitingForTeamCount) {
    return;
  }

  for (int i = 0; i < N; i++) {
    float x = railX(i);
    float y = ladderTop - 48;
    if (abs(mouseX - x) <= topBoxW / 2 && abs(mouseY - y) <= topBoxH / 2) {
      startAnimation(i);
      return;
    }
  }
}

void startAnimation(int team) {
  activeTeam = team;
  animPath = buildPath(team);
  animProgress = 0;
  isAnimating = true;
  loop();
}

ArrayList<PVector> buildPath(int team) {
  ArrayList<PVector> points = new ArrayList<PVector>();
  int pos = team;
  float rowStep = (ladderBottom - ladderTop) / (rowCount - 1.0);

  points.add(new PVector(railX(pos), ladderTop));

  for (int row = 0; row < rowCount; row++) {
    float y = ladderTop + row * rowStep;
    points.add(new PVector(railX(pos), y));

    if (pos < N - 1 && rung[row][pos]) {
      points.add(new PVector(railX(pos + 1), y));
      pos++;
    } else if (pos > 0 && rung[row][pos - 1]) {
      points.add(new PVector(railX(pos - 1), y));
      pos--;
    }
  }

  points.add(new PVector(railX(pos), ladderBottom));
  return points;
}

void keyPressed() {
  if (waitingForTeamCount) {
    if (key >= '0' && key <= '9') {
      if (!teamCountInputDirty) {
        teamCountInput = "" + key;
        teamCountInputDirty = true;
      } else if (teamCountInput.length() < 2) {
        teamCountInput += key;
      }
      redraw();
    } else if (key == BACKSPACE) {
      if (teamCountInput.length() > 0) {
        teamCountInput = teamCountInput.substring(0, teamCountInput.length() - 1);
      }
      teamCountInputDirty = teamCountInput.length() > 0;
      redraw();
    } else if (key == ENTER || key == RETURN) {
      int parsed = teamCountInput.length() == 0 ? 4 : int(teamCountInput);
      initGame(parsed);
    }
    return;
  }

  if (key == 'r' || key == 'R') {
    generateLadder();
    computeResults();
    animPath.clear();
    animProgress = 0;
    isAnimating = false;
    activeTeam = -1;
    redraw();
  }
}
