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

boolean pause = true;

public void setup() {
  size(800, 800, P3D);
  surface.setLocation(1920/2 - width/2, -1080 + 20);

  String dataPath = sketchPath("../data/");

  albedo = createGraphics(width, height, P3D);
  albedo.smooth(8);
  depth = createGraphics(albedo.width, albedo.height, P3D); 
  depthviewer = loadShader(dataPath+"depthViewer.glsl");

  PGL pgl = beginPGL();
  GL4  gl = ((PJOGL)pgl).gl.getGL4();
  depthfbo = new CustomFrameBuffer(gl, albedo.width, albedo.height);
  endPGL();

  filter = new Filter(this, albedo.width, albedo.height);
  sse = loadIncludeFragment(this, dataPath+"dof.glsl", true);
  sse.set("bluenoise", loadImage(dataPath+"blueNoise/1024_1024/LDR_RGBA_0.png"));

  pt = new PerfTracker(this, 120);
}

public void draw() {
  Time.update(this, pause);
  float nmx = norm(mouseX, 0, width);
  float nmy = norm(mouseY, 0, height);

  albedo.beginDraw();
  albedo.lights();
  albedo.background(0);

  albedo.fill(255, 0, 0);
  albedo.noStroke();
  int numSpheres = 20;
  randomSeed(1000);
  for (int i=0; i< numSpheres; i++) {
    albedo.pushMatrix();
    albedo.translate(width * i /(float)numSpheres, height/2 + 100*sin(Time.time*0.00075f + i), -400 * sin(Time.time*0.0005f + i) );
    albedo.rotateX(sin(Time.time*0.00075f + i));
    albedo.rotateZ(sin(Time.time*0.0005f + i));
    albedo.fill(random(120, 255), random(120, 255), random(120, 255));
    albedo.sphere(100* 0.5);
    albedo.box(150 * 0.5);
    albedo.popMatrix();
  }


  copyDepthToDepthFBO(albedo);
  albedo.endDraw();

  computeDepthDebugBuffer(depth);
  sse.set("depthmap", depth);
  sse.set("mouse", nmx, nmy);
  sse.set("near", 100.0);
  sse.set("far", 400.0);
  sse.set("focusPoint", 350.0);
  sse.set("scale", 1000.0);
  sse.set("resolution", (float)depth.width, (float)depth.height);
  filter.getCustomFilter(albedo, sse);

  image(filter.getBuffer(), 0, 0);

  //debug
  pt.display(0, 0);
  float scale = 0.15;
  image(albedo, 0, height - albedo.height*scale, albedo.width*scale, albedo.height*scale);
  image(depth, albedo.width*scale, height - albedo.height*scale, albedo.width*scale, albedo.height*scale);
}

void keyPressed() {
  switch(key) {
  case 'p' : 
  case 'P' : 
    pause = !pause;
    break;
  case 'S' : 
  case 's' :
    filter.getBuffer().save("DoF.png");
  break;
  }
}
