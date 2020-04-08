/* This simple scene model present a quick 3D scene and a depth buffer copy 
 */
import fpstracker.core.*;
import gpuimage.core.*;

PerfTracker pt;

Filter filter;
PShader sse;

PGraphics albedo;
PGraphics depth;
PShader depthviewer;
CustomFrameBuffer depthfbo;

public void setup() {
  size(800, 800, P3D);
  
  String dataPath = sketchPath("../data/");
  
  albedo = createGraphics(width, height, P3D);
  depth = createGraphics(albedo.width, albedo.height, P3D); 
  depthviewer = loadShader(dataPath+"depthViewer.glsl");

  PGL pgl = beginPGL();
  GL4  gl = ((PJOGL)pgl).gl.getGL4();
  depthfbo = new CustomFrameBuffer(gl, albedo.width, albedo.height);
  endPGL();
  
  filter = new Filter(this, albedo.width, albedo.height);
  //sse = loadShader(dataPath+"normalfromdepth.glsl");

  pt = new PerfTracker(this, 120);
}

public void draw() {
  float nmx = norm(mouseX, 0, width);
  float nmy = norm(mouseY, 0, height);
  
  albedo.beginDraw();
  albedo.background(0);

  albedo.fill(255, 0, 0);
  albedo.noStroke();
  int numSpheres = 8;
  for (int i=0; i< numSpheres; i++) {
    albedo.pushMatrix();
    albedo.translate(width * i /(float)numSpheres, height/2 + 100*sin(frameCount*0.02f + i), -400 * sin(frameCount*0.01f + i) );
    albedo.sphere(100);
    albedo.popMatrix();
  }


  copyDepthToDepthFBO(albedo);
  albedo.endDraw();

  computeDepthDebugBuffer(depth);
  
  //filter.getCustomFilter(depth, sse);
  //image(filter.getBuffer(), 0, 0);

  //debug
  pt.display(0, 0);
  float scale = 0.15;
  image(albedo, 0, height - albedo.height*scale, albedo.width*scale, albedo.height*scale);
  image(depth, albedo.width*scale, height - albedo.height*scale, albedo.width*scale, albedo.height*scale);
}
