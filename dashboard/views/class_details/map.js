function(doc) {
  if ( !doc.client || !doc.classes ) {
    return;
  }

  for(class in doc.classes){
    var cls = doc.classes[class];
    if ( !cls.error ) {
      emit( [doc.client, cls.name], {
        timestamp: doc.timestamp,
        client: doc.client,
        name: cls.name,
        type: cls.type,
        assertions: cls.assertions,
        complexity: cls.complexity,
        lines: cls.lines,
        methods: cls.methods.length
      });
    }
  }
}
