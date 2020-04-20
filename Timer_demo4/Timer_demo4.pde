int savedTime;
int totalTime = 5000; // time in seconds (5000=5 seconds)
PImage[] img = new PImage[3];

void setup() {
  size(200, 200);
  background(0);
  savedTime = millis();
  img[0] = loadImage("img0.jpg");
  img[1] = loadImage("img1.jpg");
  img[2] = loadImage("img2.jpg");
}

void draw() {
  int passedTime = millis() - savedTime; // calculate time passes
  if (passedTime > totalTime) { // Has five seconds passed?
    println("5 seconds have passed!");
    int index = int(random(0, img.length));  // random array
    img[index].resize(200,200); //resize
    image(img[index], 0, 0);  // draws random array corresponding with image
    savedTime = millis(); // Save the current time to restart the timer!
  }
}

//references
//http://learningprocessing.com/examples/chp10/example-10-04-timer
//https://www.youtube.com/watch?v=DPFJROWdkQ8
