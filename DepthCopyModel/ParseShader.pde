
final static int MAX_RECURSIVE_INCLUDE = 5;

public PShader loadIncludeFragment(PApplet p5, String file, boolean saveCompiled, ArrayList<String>... stringsToInsert){
    String[] frag = loadSourceShader(p5, file, stringsToInsert);
    if(saveCompiled) saveStrings(dataPath("")+"/compiledFrag.glsl", frag);

    return new PShader(this, SimpleShaderSource.vertSource, frag);
}

public PShader loadIncludeVertex(PApplet p5, String file, boolean saveCompiled, ArrayList<String>... stringsToInsert){
    String[] vert = loadSourceShader(p5, file, stringsToInsert);
    if(saveCompiled) saveStrings(dataPath("")+"/compiledVert.glsl", vert);
    return new PShader(this, vert, SimpleShaderSource.fragSource);
}

public PShader loadIncludeShader(PApplet p5, String vertFile, String fragFile, boolean saveCompiled, ArrayList<String>... stringsToInsertInVertFrag){
    String[] vert = loadSourceShader(p5, vertFile, stringsToInsertInVertFrag[0]);
    String[] frag = loadSourceShader(p5, fragFile, stringsToInsertInVertFrag[1]);
    if(saveCompiled){
        saveStrings(dataPath("")+"/compiledVert.glsl", vert);
        saveStrings(dataPath("")+"/compiledFrag.glsl", frag);
    }
    return new PShader(this, vert, frag);
}

public String[] loadSourceShader(PApplet p5, String file, ArrayList<String>... stringsToInsert){
    ArrayList<String> list = new ArrayList<String>();
    loadSourceShader(p5, 0, list, file);
    if(stringsToInsert.length > 0){
        for(ArrayList<String> AS : stringsToInsert)
            injectStrings(list, AS);
    }
    String[] tmpshader = new String[list.size()];
    tmpshader = list.toArray(tmpshader);
    return tmpshader;
}


public void injectStrings(ArrayList<String> source, ArrayList<String> stringsToInsert) {
  int index = -1;
  for (int i=0; i < source.size(); i++) {
    if (source.get(i).contains("#version")) {
      index = i;
      break;
    }
  }
  source.addAll(index+1, stringsToInsert);
}


//Adapted by Nacho Cossio from PixelFlow library, DwGLSLShader.java
public static void loadSourceShader(PApplet p5, int depth, ArrayList<String> source, String path){
    System.out.println("parsing file: "+ path+" at depth"+depth);	    

    String[] lines = p5.loadStrings(path);

    if(depth++ > MAX_RECURSIVE_INCLUDE){
        throw new StackOverflowError("recursive #include: "+path);
    }
        
    for(int i = 0; i < lines.length; i++)
    {
        String line = lines[i];
        String line_trim = line.trim();
        if(line_trim.startsWith("#include")){
            String include_file = line_trim.substring("#include".length()).replace("\"", "").trim();
            loadSourceShader(p5, depth, source, include_file);
        } else {
            source.add(line);
        }
    }
}

static interface SimpleShaderSource {
  public final static String[] vertSource = {
    "#version 150",
    "uniform mat4 transformMatrix;",
    "uniform mat4 texMatrix;",
    "in vec4 position;",
    "in vec4 color;",
    "in vec2 texCoord;",
    "out vec4 vertColor;",
    "out vec4 vertTexCoord;",
    "void main() {",
    "gl_Position = transformMatrix * position;",
    "vertColor = color;",
    "vertTexCoord = texMatrix * vec4(texCoord, 1.0, 1.0);",
    "}"
  };

  public final static String[] fragSource = {
    "#version 150",
    "#ifdef GL_ES", 
    "precision mediump float;", 
    "precision mediump int;", 
    "#endif", 
    "in vec4 vertColor;",
    "in vec4 vertTexCoord;",
    "out vec4 fragColor:",
    "void main() {", 
    "gl_FragColor = vertColor;", 
    "}"
  };
}

