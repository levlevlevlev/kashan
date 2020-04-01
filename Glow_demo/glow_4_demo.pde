void setup() {
  size(226,206);
  background(235,224,206);
  noStroke();
  noStroke();
  frameRate(120);
}

void draw(){
  fill(0, 10);
  rect(0 ,0 , width, height);
  
  fill(255, 191, 0, 40);
  filter(BLUR,2);
  ellipse(mouseX, mouseY, 120, 120);
  
}
