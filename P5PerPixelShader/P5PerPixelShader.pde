PShader shader;

void setup(){
  size(500, 500, P3D);
  smooth(8);
  
  shader = loadShader("P5_DefaultFrag.glsl", "P5_DefaultVert.glsl");
}

void draw(){
  translate(width/2, height/2, -250);
  rotateY(frameCount * 0.01);
  background(20);
  
  
  //lights();
  pointLight(255, 0, 0, -250, 0, 0);
  pointLight(0, 255, 0, 0, -250, 0);
  pointLight(0, 0, 255, 0, 0, -250);
  
  
  shader(shader);
  noStroke();
  sphere(150);
}
