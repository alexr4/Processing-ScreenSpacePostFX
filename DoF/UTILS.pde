/*Copy the depth buffer from the albedo to another buffer
from @NachoCossio — https://github.com/kosowski/Processing_DepthBuffer
*/
void copyDepthToDepthFBO(PGraphics b){
  PGL pgl = b.beginPGL();
  FrameBuffer fbo = ((PGraphicsOpenGL)b).getFrameBuffer(true);
  depthfbo.copyDepthFrom(pgl, fbo.glFbo);
  b.endPGL();
}

void bindDepthBuffer(PJOGL pjogl, PShader shader, String uniformID){
  int textureID = depthfbo.getDepthTexture()[0];
  int textureUnit = PGL.TEXTURE2;
  pjogl.activeTexture(textureUnit);
  pjogl.bindTexture(PGL.TEXTURE_2D, textureID);
  shader.set(uniformID, textureID);
}

void computeDepthDebugBuffer(PGraphics b){
  b.beginDraw();
  PGL pgl = b.beginPGL();
  PJOGL  pjogl = ((PJOGL)pgl);
  bindDepthBuffer(pjogl, depthviewer, "depthTexture");
  b.endPGL();

  b.background(0);
  b.shader(depthviewer);
  b.rect(0, 0, b.width, b.height);
  b.endDraw();
}
