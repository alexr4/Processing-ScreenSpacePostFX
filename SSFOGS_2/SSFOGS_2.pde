/* This simple scene model present a quick 3D scene and a depth buffer copy 
 */
import fpstracker.core.*;
import gpuimage.core.*;

PerfTracker pt;

Filter filter;
PShader sse;

PVector lightDir;
PShader scenesh;
PGraphics albedo;
PGraphics depth;
PShader depthviewer;
CustomFrameBuffer depthfbo;

boolean pause = false;

public void setup() {
  size(800, 800, P3D);

  surface.setLocation(1920/2 - width/2, -0 + 100);

  String dataPath = sketchPath("../data/");
  String fogType = "#define FOGTYPE 0";
  ArrayList paramsVert = new ArrayList<String>();
  ArrayList paramsFrag = new ArrayList<String>();
  paramsVert.add("");
  paramsFrag.add(fogType);
  scenesh = loadIncludeShader(this, dataPath+"P5_DefaultVert.glsl", dataPath+"P5_DefaultFrag.glsl", true, paramsVert, paramsFrag);
  lightDir = new PVector();
  albedo = createGraphics(width, height, P3D);
  depth = createGraphics(albedo.width, albedo.height, P3D); 
  depthviewer = loadShader(dataPath+"depthViewer.glsl");

  PGL pgl = beginPGL();
  GL4  gl = ((PJOGL)pgl).gl.getGL4();
  depthfbo = new CustomFrameBuffer(gl, albedo.width, albedo.height);
  endPGL();

  filter = new Filter(this, albedo.width, albedo.height);
  sse = loadIncludeFragment(this, dataPath+"ssfog-2.glsl", false, paramsFrag);

  Time.setStartTime(this);
  pt = new PerfTracker(this, 120);
}

public void draw() {
  Time.update(this, pause);
  float nmx = norm(mouseX, 0, width);
  float nmy = norm(mouseY, 0, height);

  float lightAngle = Time.time * 0.001;
  float lfar = 750;
  lightDir.set(sin(lightAngle), nmx * 2.0 - 1.0, cos(lightAngle));

  PVector fogColor = new PVector(0.9137, 0.9608, 0.9882);
  float near = 500.0 * 1.0;
  float maxFar = 2500.0;
  float far = (maxFar - near) * 0.25 + near;


  albedo.beginDraw();
  albedo.shader(scenesh);
  albedo.background(fogColor.x * 255.0, fogColor.y * 255.0, fogColor.z * 255.0); 

  albedo.pushMatrix();
  albedo.translate(width/2, height/2);
  albedo.fill(fogColor.x * 255.0, fogColor.y * 255.0, fogColor.z * 255.0);
  albedo.stroke(0);
  //albedo.sphere(750);
  albedo.line(0, 0, 0, lightDir.x * 100, lightDir.y * 100, lightDir.z * 100);
  albedo.popMatrix();

  albedo.lightFalloff(0.5, 0.001, 0.0);
  albedo.ambientLight(255/2.5, 255/2.5, 255/2.5, 0, 0, 0);
  albedo.pointLight(0.9882 * 255 * 0.5, 0.9529 * 255 * 0.5, 0.9137 * 255 * 0.5, 0, height/2, 1500);
  albedo.lightSpecular(255, 255, 255.0);
  albedo.directionalLight(0.9882 * 255.0, 0.9804 * 255.0, 0.9137 * 255.0, lightDir.x * -1, lightDir.y * -1, lightDir.z * -1);
  albedo.lightSpecular(255/2, 255/2, 255/2);

  albedo.ambient(75, 75, 75);
  albedo.emissive(5, 5, 5);
  albedo.specular(25, 25, 25);
  albedo.shininess(100.0);
  albedo.noStroke();
  randomSeed(1000);
  int numSpheres = 8;
  for (int i=0; i< numSpheres; i++) {
    albedo.pushMatrix();
    albedo.translate(width * i /(float)numSpheres, height/2 + 100*sin(frameCount*0.02f + i), -400 * sin(frameCount*0.01f + i) );
    albedo.fill(random(127, 255), random(127, 255), random(127, 255));
    albedo.shininess(random(100, 1000.0));
    albedo.sphere(100);
    albedo.popMatrix();
  }


  copyDepthToDepthFBO(albedo);
  albedo.endDraw();

  computeDepthDebugBuffer(depth);

  PMatrix3D projmat = ((PGraphicsOpenGL)albedo).projection;
  //PMatrix3D modelview = ((PGraphicsOpenGL)albedo).modelviewInv;

   sse.set("projmat", new PMatrix3D(
    projmat.m00, projmat.m10, projmat.m20, projmat.m30, 
    projmat.m01, projmat.m11, projmat.m21, projmat.m31, 
    projmat.m02, projmat.m12, projmat.m22, projmat.m32, 
    projmat.m03, projmat.m13, projmat.m23, projmat.m33
    ));
  //sse.set("mv", modelview);
  sse.set("depthmap", depth);
  sse.set("near", near);
  sse.set("far", far);
  sse.set("fogColor", fogColor);
  sse.set("sunDir", lightDir);
  sse.set("fogDensity", nmx * 0.01);
  sse.set("mouse", nmx, nmy);
  sse.set("resolution", (float)albedo.width, (float)albedo.height);
  sse.set("time", Time.time * 0.00015);

  filter.getCustomFilter(albedo, sse);
  image(filter.getBuffer(), 0, 0);
  //image(albedo, 0, 0);

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
  }
}
