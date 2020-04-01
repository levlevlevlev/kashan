PImage img ;

void setup() {
  size(226,206);
  background(0);
  noStroke();
  frameRate(120);
  img = loadImage("desat.png");

}

void draw(){
  
  fill(0,5);
  rect(0 ,0 , width, height);
  
  fill(255, 200, 0, 40);
 // filter(BLUR,2);
  ellipse(mouseX, mouseY, 120, 120);
  image(img, 0, 0);
  
}
