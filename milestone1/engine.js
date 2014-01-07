/*
  aquator prototype engine
  by uli@krispel.net
*/


function CatmullRom( t, P )
{
  return 0.5 * (  (2.0*P[1]) + (P[2]-P[0])*t + (2.0*P[0]-5.0*P[1]+4.0*P[2]-P[3])*t*t + (3.0*P[1]-P[0]-3*P[2]+P[3])*t*t*t );
}

function evaluateSpline(t, CPX, CPY)
{
  // assume evenly spaced segments
  var numcp = CPX.length;
  var numsegments = numcp-3;
  
  // determine segment
  var tt = t*numsegments;
  var i = Math.floor(tt);
  tt = tt-i;
  
  // the spline for the i-th segment is evaluated from
  // controlpoints i,i+1,i+2,i+3
  var cpx = [ CPX[i], CPX[i+1], CPX[i+2], CPX[i+3] ];
  var cpy = [ CPY[i], CPY[i+1], CPY[i+2], CPY[i+3] ];
  
  var point={};
  point.x = CatmullRom( tt, cpx );
  point.y = CatmullRom( tt, cpy );
  return point; 
}

