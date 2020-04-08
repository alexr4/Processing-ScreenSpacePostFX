/* This simple scene model present a quick 3D scene and a depth buffer copy 
https://forum.unity.com/threads/screen-space-multiple-scattering.446647/
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

boolean pause;

public void setup() {
  size(800, 800, P3D);

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
  sse = loadIncludeFragment(this, dataPath+"ssms-2.glsl", true);
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
  int numSpheres = 8;
  for (int i=0; i< numSpheres; i++) {
    albedo.pushMatrix();
    albedo.translate(width * i /(float)numSpheres, height/2 + 100*sin(Time.time*0.00075f + i), -400 * sin(Time.time*0.0005f + i) );
    albedo.rotateX(sin(Time.time*0.00075f + i));
    albedo.rotateZ(sin(Time.time*0.0005f + i));
    albedo.sphere(100);
    albedo.box(150);
    albedo.popMatrix();
  }


  copyDepthToDepthFBO(albedo);
  albedo.endDraw();
 
  
  computeDepthDebugBuffer(depth);
  sse.set("depthmap", depth);
  
  
  
  sse.set("blurred", filter.getBuffer());
  sse.set("mouse", nmx, nmy);
  sse.set("near", 10.0);
  sse.set("far", 400.0);
  sse.set("resolution", (float)depth.width, (float)depth.height);
  sse.set("dir", 1.0, 0.0, (float)depth.width);
  
  PGraphics h = createGraphics(width, height, P2D);
  h.beginDraw();
  h.blendMode(REPLACE);
  h.shader(sse);
  h.image(albedo, 0, 0);
  h.endDraw();
  
  sse.set("dir", 0.0, 1.0, (float)depth.height);
  PGraphics v = createGraphics(width, height, P2D);
  v.beginDraw();
  v.blendMode(REPLACE);
  v.shader(sse);
  v.image(h, 0, 0);
  v.endDraw();
  
  
  //filter.getCustomFilter(albedo, sse);
  image(v, 0, 0);
  
  //

  //debug
  pt.display(0, 0);
  float scale = 0.15;
  image(albedo, 0, height - albedo.height*scale, albedo.width*scale, albedo.height*scale);
  image(depth, albedo.width*scale, height - albedo.height*scale, albedo.width*scale, albedo.height*scale);
}

void keyPressed() {
  switch(key) {
  case 'p' : 
    pause = !pause;
    break;
  }
}
