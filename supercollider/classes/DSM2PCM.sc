DSM2PCM : UGen
{
  *ar { | in1, freq(100.0) |
      ^this.multiNew('audio', in1, freq)
  }

  *kr { | in1, freq(100.0) |
      ^this.multiNew('control', in1, freq)
  } 

  checkInputs {
    if (rate == 'audio', {
      1.do({|i|
        if (inputs.at(i).rate != 'audio', {
          ^(" input at index " + i + "(" + inputs.at(i) + 
            ") is not audio rate");
        });
      });
    });
    ^this.checkValidInputs
  }

  name { ^"DSM2PCM" }


  info { ^"Generated with Faust" }
}

