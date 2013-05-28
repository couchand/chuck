function(k,v,r){
  var newest = v[0];

  for ( var i in v ) {
    if  ( v[i].timestamp > newest.timestamp ) {
      newest = v[i];
    }
  }

  return newest;
}
