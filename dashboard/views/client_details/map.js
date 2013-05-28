var A_CUTOFF = 3;
var B_CUTOFF = 8;
var C_CUTOFF = 12;
var D_CUTOFF = 20;

function(doc) {
  if ( !doc.client || !doc.classes ) {
    return;
  }

  for(class in doc.classes){
    var cls = doc.classes[class];

    if ( !cls.error ) {
      var grade = 'F';
      if ( cls.complexity / cls.methods.length < D_CUTOFF ) grade = 'D';
      if ( cls.complexity / cls.methods.length < C_CUTOFF ) grade = 'C';
      if ( cls.complexity / cls.methods.length < B_CUTOFF ) grade = 'B';
      if ( cls.complexity / cls.methods.length < A_CUTOFF ) grade = 'A';

      emit( [doc.client, grade], {
        timestamp: doc.timestamp,
        client: doc.client,
        name: cls.name,
        grade: grade,
        complexity: cls.complexity,
        lines: cls.lines,
        methods: cls.methods.length
      });
    }
  }
}
