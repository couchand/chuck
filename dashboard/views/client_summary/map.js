function(doc) {
  if ( !doc.classes || "undefined" != typeof doc.classes[0].SymbolTable ) {
    return;
  }

  var m = {
    "timestamp": doc.timestamp,
    "classes": 0,
    "parse": 0,
    "complexity": 0,
    "lines": 0
  };

  for(class in doc.classes){
    var cls = doc.classes[class];
    m.classes++;
    if( !cls.error ){
      m.parse++;
      m.complexity += cls.complexity || 0;
      m.lines += cls.lines || 0;
    }
  }

  emit(doc.client, m);
}
