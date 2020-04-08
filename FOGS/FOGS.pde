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

public void setup() {
  size(800, 800, P3D);

  String dataPath = sketchPath("../data/");
  String fogType = "#define FOGTYPE 0";
  ArrayList paramsVert = new ArrayList<String>();
  ArrayList paramsFrag = new ArrayList<String>();
  paramsVert.add("");
  paramsFrag.add(fogType);
  scenesh = loadIncludeShader(this, dataPath+"P5_DefaultVert.glsl", dataPath+"P5_DefaultFrag-Fog.glsl", true, paramsVert, paramsFrag);
  lightDir = new PVector();
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
  
  float lightAngle = frameCount * 0.002;
  float lfar = 750;
  lightDir.set(sin(lightAngle) * lfar, lfar, cos(lightAngle) * lfar);
  
  PVector fogColor = new PVector(0.9137, 0.9608, 0.9882);
  float near = 500.0 * nmy;
  float maxFar = 2500.0;
  float far = (maxFar - near) * nmx + near;
  scenesh.set("near", near);
  scenesh.set("far", far);
  scenesh.set("fogColor", fogColor);
  fogColor.mult(255);

  albedo.beginDraw();
  albedo.shader(scenesh);
  albedo.background(fogColor.x, fogColor.y, fogColor.z);
  albedo.lightFalloff(0.5, 0.001, 0.0);
  albedo.ambientLight(255/2, 255/2, 255/2, 0, 0, 0);
  albedo.pointLight(0, 255/4.0, 0, 0, height/2, 500);
  albedo.lightSpecular(255/2, 255/2, 0);
  albedo.directionalLight(0, 0, 255/2, lightDir.x * -1, lightDir.y * -1, lightDir.z * -1);
  albedo.lightSpecular(0, 255/2, 255/2);
  
  albedo.ambient(255, 0, 0);
  albedo.emissive(0, 5, 0);
  albedo.specular(255, 255, 255);
  albedo.shininess(100.0);
  albedo.noStroke();
  randomSeed(1000);
  int numSpheres = 8;
  for (int i=0; i< numSpheres; i++) {
    albedo.pushMatrix();
    albedo.translate(width * i /(float)numSpheres, height/2 + 100*sin(frameCount*0.02f + i), -400 * sin(frameCount*0.01f + i) );
    albedo.fill(random(127, 255), random(127, 255), random(127, 255));
    albedo.sphere(100);
    albedo.popMatrix();
  }


  copyDepthToDepthFBO(albedo);
  albedo.endDraw();

  computeDepthDebugBuffer(depth);

  //filter.getCustomFilter(depth, sse);
  //image(filter.getBuffer(), 0, 0);
  image(albedo, 0, 0);

  //debug
  pt.display(0, 0);
  float scale = 0.15;
  image(albedo, 0, height - albedo.height*scale, albedo.width*scale, albedo.height*scale);
  image(depth, albedo.width*scale, height - albedo.height*scale, albedo.width*scale, albedo.height*scale);
}
