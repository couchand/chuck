function(doc) {
  if ( !doc.classes) {
    return;
  }

  for(class in doc.classes){
    var cls = doc.classes[class];
    if( !cls.error ){
      emit( doc.client + ":" + cls.name, {
        "client": doc.client,
        "name": cls.name,
        "complexity": cls.complexity || 0,
        "methods": cls.methodCount,
        "lines": cls.lines
      });
    }
  }
}
