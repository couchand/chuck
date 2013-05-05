function (doc) {
  if ( !doc.classes || !doc.classes[0] || !doc.classes[0].SymbolTable ) {
    return;
  }
  for ( i in doc.classes ) {
    cls = doc.classes[i];
    for ( j in cls.SymbolTable.externalReferences ) {
      ref = cls.SymbolTable.externalReferences[j];
      emit(ref.name + ":" + cls.SymbolTable.name, {
        "from": cls.SymbolTable.name,
        "to": ref.name,
        "count": ref.references.length
      });
    }
  }
}
