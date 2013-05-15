function(doc) {
  if ( !doc.client || !doc.scans ) {
    return;
  }

  for(i in doc.scans){
  scan = doc.scans[i];
  if ( scan.timestamp == "2013-05-13T18:53:09.161Z") continue;

  for(class in scan.classes){
    var cls = scan.classes[class];
    if( !cls.error ){
      emit( doc.client + ":" + cls.name + ":" + scan.timestamp, {
        "client": doc.client,
        "name": cls.name,
        "timestamp": scan.timestamp,
        "complexity": cls.complexity || 0,
        "methods": cls.methodCount,
        "lines": cls.lines
      });
    }
    else {
      emit( doc.client + ":" + cls.name + ":" + scan.timestamp, {
        "client": doc.client,
        "name": cls.name,
        "timestamp": scan.timestamp,
        "error": cls.error
      });
    }
  }
}
}
