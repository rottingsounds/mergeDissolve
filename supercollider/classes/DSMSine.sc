DSMSine : UGen
{
  *ar { | freq(100.0) |
      ^this.multiNew('audio', freq)
  }

  *kr { | freq(100.0) |
      ^this.multiNew('control', freq)
  } 

  name { ^"DSMSine" }


  info { ^"Generated with Faust" }
}

