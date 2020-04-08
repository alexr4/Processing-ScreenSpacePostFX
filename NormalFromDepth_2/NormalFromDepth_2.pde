/* This simple scene model present a quick 3D scene and a depth buffer copy 
from : https://wickedengine.net/2019/09/22/improved-normal-reconstruction-from-depth/
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
  sse = loadShader(dataPath+"normalfromdepth-2.glsl");

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
    albedo.rotateX(sin(frameCount*0.02f + i));
    albedo.rotateZ(sin(frameCount*0.01f + i));
    albedo.sphere(100);
    albedo.box(150);
    albedo.popMatrix();
  }


  copyDepthToDepthFBO(albedo);
  albedo.endDraw();

  computeDepthDebugBuffer(depth);
  
  PMatrix3D modelviewInv = ((PGraphicsOpenGL)albedo).projection;
  
  sse.set("mouse", nmx, nmy);
  //sse.set("InvVP", new PMatrix3D(
  //  modelviewInv.m00, modelviewInv.m10, modelviewInv.m20, modelviewInv.m30, 
  //  modelviewInv.m01, modelviewInv.m11, modelviewInv.m21, modelviewInv.m31, 
  //  modelviewInv.m02, modelviewInv.m12, modelviewInv.m22, modelviewInv.m32, 
  //  modelviewInv.m03, modelviewInv.m13, modelviewInv.m23, modelviewInv.m33
  //  ));
    sse.set("InvVP", modelviewInv);
  filter.getCustomFilter(depth, sse);
  
  image(filter.getBuffer(), 0, 0);

  //debug
  pt.display(0, 0);
  float scale = 0.15;
  image(albedo, 0, height - albedo.height*scale, albedo.width*scale, albedo.height*scale);
  image(depth, albedo.width*scale, height - albedo.height*scale, albedo.width*scale, albedo.height*scale);
}
