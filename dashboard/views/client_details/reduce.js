function(k,v,r){
  var newest = v[0];

  for ( var i in v ) {
    if ( v[i].timestamp > newest.timestamp ) {
      newest = v[i];
    }
  }

  var vals = {
    client: newest.client,
    grade: newest.grade,
    classes: 0,
    methods: 0,
    lines: 0
  };

  for ( var i in v ) {
    if ( v[i].timestamp == newest.timestamp ) {
      vals.classes++;
      vals.methods += v[i].methods;
      vals.lines += v[i].lines;
    }
  }

  return vals;
}
