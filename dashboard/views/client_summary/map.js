function(doc) {
  if ( !doc.classes ) {
    return;
  }

  var m = {
    classes: 0,
    parse: 0,
    complexity: 0,
    lines: 0
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
