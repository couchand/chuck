function(doc) {
  var classes = [];

  for(class in doc.classes){
  var cls = doc.classes[class];
    if( !cls.error ){
      classes.push({
        name: cls.name,
        complexity: cls.complexity || 0,
        methods: cls.methodCount,
        lines: cls.lines
      });
    }
    else {
      classes.push({ name: cls.name, error: true });
    }
  }

  emit(doc.client, classes);
}
