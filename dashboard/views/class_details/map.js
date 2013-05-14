function(doc) {
  if ( !doc.client || !doc.scans ) {
    return;
  }

  for(class in doc.scans[0].classes){
    var cls = doc.scans[0].classes[class];
    if( !cls.error ){
      emit( doc.client + ":" + cls.name, {
        "client": doc.client,
        "name": cls.name,
        "complexity": cls.complexity || 0,
        "methods": cls.methodCount,
        "lines": cls.lines
      });
    }
    else {
      emit( doc.client + ":" + cls.name, {
        "client": doc.client,
        "name": cls.name,
        "error": cls.error
      });
    }
  }
}
