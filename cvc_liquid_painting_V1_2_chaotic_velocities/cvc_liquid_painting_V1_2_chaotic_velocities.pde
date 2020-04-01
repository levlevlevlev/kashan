/*

  CVC_streamLines
  
  Shows using CVClient (ComputerVisionClient) to connect to VideoTracker, 
  read blob data and some different ideas to render it.
  
  Dependencies: controlP5, cvc.jar (included in code folder) & bbc_utils.jar (included in code folder)
  this implementaion and the jar file dependences  are not currently openscourced
  and are owned by Brad Miller 
  and can only be used without permission for class ADAD3402 @ UNSW 2017
*/

import java.util.Map;
import controlP5.*;
import cvc.CVClient;
import cvc.events.TrackingEvent;
import cvc.blobs.TrackingBlob;

import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.fluid.DwFluidParticleSystem2D;

import controlP5.Accordion;
import controlP5.ControlP5;
import controlP5.Group;
import controlP5.RadioButton;
import controlP5.Toggle;
import processing.core.*;
import processing.opengl.PGraphics2D;

CVClient cvc;

float my_x;
float my_y;
float getXSpeed;
float getMotionSpeed;
float getYSpeed;
// some state variables for the GUI/display

// some state variables for the GUI/display
int     BACKGROUND_COLOR           = 255;
boolean UPDATE_FLUID               = true;
boolean DISPLAY_FLUID_TEXTURES     = true;
boolean DISPLAY_FLUID_VECTORS      = false;
int     DISPLAY_fluid_texture_mode;
boolean DISPLAY_PARTICLES          = false;
boolean CVC_DEBUG_RENDER           = true; // true

PImage image;
  
  int viewport_w = 1200;
  int viewport_h = 769; //600
  int viewport_x = 230;  //230
  int viewport_y = 0; //0
  
  int gui_w = 200;
  int gui_x = 20;
  int gui_y = 20;
  
  int fluidgrid_scale = 1; //2
  // library
  DwPixelFlow context;
  
  // Fluid simulation
  DwFluid2D fluid;
  
  MyFluidData cb_fluid_data;
  DwFluidParticleSystem2D particle_system;

  // render targets
  PGraphics2D pg_fluid;       // render target
  PGraphics2D pg_image;       // texture-buffer, for adding fluid data

    
  public void settings() {
    
    size(viewport_w, viewport_h, P2D);
    //pixelDensity(1);
    //pixelDensity(displayDensity());
    //fullScreen(P2D);
    smooth(4);
  }

void setup() {
    cvc = new CVClient(this);
    cvc.setMinimalLogging(); // Dont show so much in the console
    cvc.init(); // initialise CVC
    cvc.registerEvents(this); // register for the blob tracking events, your code must have methods updateTrackingBlobs & removeTrackingBlobs 
    // Setup VideoTracker server connection and connect
    cvc.setTrackingServer("127.0.0.1", 11001); // ip, port
    
    cvc.showControlPanel(10, height-165);

 //particle system   
    // main library context
    context = new DwPixelFlow(this);
    context.print();
    context.printGL();
    
    // fluid simulation
    fluid = new DwFluid2D(context, width, height, fluidgrid_scale);
  
    // set some simulation parameters
    fluid.param.dissipation_density     = 1.0f;
    fluid.param.dissipation_velocity    = 1.25f; // controls power of velocity
                                                 // looks cool with 1.25, doesn't reset quick
    fluid.param.dissipation_temperature = 0.70f;
    fluid.param.vorticity               = 0.50f;
    
    // interface for adding data to the fluid simulation
    cb_fluid_data = new MyFluidData();
    fluid.addCallback_FluiData(cb_fluid_data);
    
    // image, used for density
    image = loadImage("kashan.jpg");


    // pgraphics for fluid
    pg_fluid = (PGraphics2D) createGraphics(width, height, P2D);
    pg_fluid.smooth(2);
    
    // particles
    particle_system = new DwFluidParticleSystem2D();
    particle_system.resize(context, viewport_w/3, viewport_h/3);

// image/buffer that will be used as density input
    pg_image = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
    pg_image.noSmooth();
    pg_image.beginDraw();
    pg_image.clear();
    pg_image.translate(width/2, height/2);
    pg_image.scale(viewport_h / (float)image.height);
    pg_image.imageMode(CENTER);
    pg_image.image(image, 0, 0);
    pg_image.endDraw();
    
    
    createGUI(); //call GUI
    image(image, 0, 0);
    //background(0);
    frameRate(120);
    
}

void draw() {

    
    cvc.update();
    
    if(CVC_DEBUG_RENDER) { 
      cvc.drawImage(5, 5, 160, 120, true); // debug show copy of the image
    }
    
    // update simulation
    if(UPDATE_FLUID){
      fluid.update();
      particle_system.update(fluid);
    }
    
    
     // update simulation
   
    
    // clear render target
    pg_fluid.beginDraw();
    pg_fluid.background(image);
    pg_fluid.endDraw();
    
    
    // render fluid stuff
    if(DISPLAY_FLUID_TEXTURES){
      // render: density (0), temperature (1), pressure (2), velocity (3)
      fluid.renderFluidTextures(pg_fluid, DISPLAY_fluid_texture_mode);
    }
    
    if(DISPLAY_FLUID_VECTORS){
      // render: velocity vector field
      fluid.renderFluidVectors(pg_fluid, 10);
    }


    if(DISPLAY_PARTICLES){
      particle_system.render(pg_fluid, null, 0);
    }

    // display
    image(pg_fluid, 0, 0); // render the content to the screen buffer  
    
    
     if(CVC_DEBUG_RENDER) {
      cvc.render(0,0); // render the debug graphics
    }

    String txt_fps = String.format(getClass().getName()+ "   [size %d/%d]   [frame %d]   [fps %6.2f]", fluid.fluid_w, fluid.fluid_h, fluid.simulation_step, frameRate);
    surface.setTitle(txt_fps);   
}

void updateTrackingBlobs(TrackingEvent event) {
  
  pushStyle();
 
  // Loop through all the Tracking blobs found in event.update_blobs
  
  for(Map.Entry<Integer,TrackingBlob> entry : event.updated_blobs.entrySet()) {  // This is how we loop thru a ConcurrentHashMap (which CVC uses to be thread safe) 
    TrackingBlob blob = entry.getValue(); // See notes below on methods to access TrackingBlob    
  
    //println("blob x speed: " + blob.getXSpeed());
    //println("motion speed: " + blob.getMotionSpeed());
    
  
  //particles  
     //setting up floats for all future use
        float px, py, vx, vy, radius, vscale;

        my_x = blob.getPos().x;
        my_y = blob.getPos().y;
      
      // add impulse: density + velocity, particles
   //   if(mouseButton == LEFT){
        radius = random(1, 2); //size of particle explosion!
        vscale = random(1, 2); //velocity scale?

        px = my_x;
        py = height - my_y;
        
        
        vx = random(-1, 1) * +vscale; // note the random(-5, 5) produces a number 
        vy = random(-1, 1) * -vscale;
        
        radius = 50;
        fluid.addDensity(px, py, radius, 1, 1, 1f, 1.0f);
        radius = 15;
        fluid.addVelocity(px, py, radius, vx, vy);
     //}
     
     // use the text as input for density
      float mix = fluid.simulation_step == 0 ? 1.0f : 0.01f;
      addDensityTexture(fluid, pg_image, mix);
    }
  
// custom shader, to add density from a texture (PGraphics2D) to the fluid.
  popStyle();
}
  
void removeTrackingBlobs( TrackingEvent event ) {
  // event.removed_blob_ids ArrayList of ints of the ids of blobs removed.
  // You can use this to remove your own blobs if you have created some

}

 public void fluid_resizeUp(){
  fluid.resize(width, height, fluidgrid_scale = max(1, --fluidgrid_scale));
}
public void fluid_resizeDown(){
  fluid.resize(width, height, ++fluidgrid_scale);
}
public void fluid_reset(){
  fluid.reset();
}
public void fluid_togglePause(){
  UPDATE_FLUID = !UPDATE_FLUID;
}
public void fluid_displayMode(int val){
  DISPLAY_fluid_texture_mode = val;
  DISPLAY_FLUID_TEXTURES = DISPLAY_fluid_texture_mode != -1;
}
public void fluid_displayVelocityVectors(int val){
  DISPLAY_FLUID_VECTORS = val != -1;
}
 

//particle system
  private class MyFluidData implements DwFluid2D.FluidData{
    
    // update() is called during the fluid-simulation update step.
    @Override
    public void update(DwFluid2D fluid) {
     
  }
   
}
void keyPressed() {
  
  // Toggle the CVC debug rendering
  if(key == 'D' || key == 'd') CVC_DEBUG_RENDER = !CVC_DEBUG_RENDER; 
  if(key == 'E' || key == 'e') DISPLAY_fluid_texture_mode = int(random(4));
  if(key == 'C' || key == 'c') cvc.toggleControlPanel();
  
  if(key == 'p') fluid_togglePause(); // pause / unpause simulation
  if(key == '+') fluid_resizeUp();    // increase fluid-grid resolution
  if(key == '-') fluid_resizeDown();  // decrease fluid-grid resolution
  if(key == 'r') fluid_reset();       // restart simulation
    
  if(key == '1') DISPLAY_fluid_texture_mode = 0; // density
  if(key == '2') DISPLAY_fluid_texture_mode = 1; // temperature
  if(key == '3') DISPLAY_fluid_texture_mode = 2; // pressure
  if(key == '4') DISPLAY_fluid_texture_mode = 3; // velocity
  
}
void addDensityTexture(DwFluid2D fluid, PGraphics2D pg, float mix){
  int[] pg_tex_handle = new int[1];
//      pg_tex_handle[0] = pg.getTexture().glName;
  context.begin();
  context.getGLTextureHandle(pg, pg_tex_handle);
  context.beginDraw(fluid.tex_density.dst);
  DwGLSLProgram shader = context.createShader(this, "data/addDensity.frag");
  shader.begin();
  shader.uniform2f     ("wh"        , fluid.fluid_w, fluid.fluid_h);                                                                   
  shader.uniform1i     ("blend_mode", 6);   
  shader.uniform1f     ("mix_value" , mix);     
  shader.uniform1f     ("multiplier", 1);     
  shader.uniformTexture("tex_ext"   , pg_tex_handle[0]);
  shader.uniformTexture("tex_src"   , fluid.tex_density.src);
  shader.drawFullScreenQuad();
  shader.end();
  context.endDraw();
  context.end("app.addDensityTexture");
  fluid.tex_density.swap();
}

/*

  Useful public methods of the cvc.blobs.TrackingBlob class
  
  RectangleF getRect() // bounding box of blob
  float getArea() // of rect
  
  PVector getPos() // location of centroid
  PVector getDecPos() // a normalised position vector 0..1  
  
  int getID()
  
  boolean hasOutlines()
  float[] getOutlines() // array of [x,y,x,y,x,y...] coordinates  
  int getOutlinesCount()  
  
  long getAge(){ // how old in milliseconds this blob is  
  long getStagnation(){ // how long it has been still
  
  float getXSpeed() // X velocity
  float getYSpeed() // the Y velocity
  float getMotionSpeed()
  float getMotionAccel()
   
  boolean isMoving()
    
  int getState() // possible values: TracingBlob.ADDED, TracingBlob.ACCELERATING, TracingBlob.DECELERATING, TracingBlob.STOPPED, TracingBlob.REMOVED

  String getStateString() // small readable version of the state: 
  
*/
