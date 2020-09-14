// efx for matrix
(
SynthDef(\delayFX, {|in1, in2, gate = 1, fadeTime = 1|
	var frame = 2048;
	var rFrame = frame.reciprocal;
	var rSR = SampleRate.ir.reciprocal;
	var maxDelay = 1;

	var input1 = In.ar(in1);
	var input2 = In.ar(in2);
	var xfade = Env.asr(fadeTime, 1, fadeTime, 1).kr(2, gate);

	// the louder, the less delay
	// var dt = RunningSum.ar(input2 > 0, frame) * rFrame * maxDelay; // ensure values between 0..maxDelay
	var dt = RMS.ar(input2 > 0) * rFrame * maxDelay; // ensure values between 0..maxDelay
	dt = Line.kr(0, 1, 10) * dt;

	// dt.poll;

	XOut.ar(in1, xfade, DelayN.ar(input1, maxDelay, dt.lag(0.01)));
}).add;

SynthDef(\delayFX_inv, {|in1, in2, gate = 1, fadeTime = 1|
	var frame = 2048;
	var rFrame = frame.reciprocal;
	var rSR = SampleRate.ir.reciprocal;
	var maxDelay = 1;

	var input1 = In.ar(in1) > 0;
	var input2 = In.ar(in2) > 0;

	var xfade = Env.asr(fadeTime, 1, fadeTime, 1).kr(2, gate);
	// the louder, the less delay
	var dt = maxDelay - (RunningSum.ar(input2 > 0, frame) * rFrame * maxDelay); // ensure values between 0..maxDelay
	dt = Line.kr(0, 1, 10) * dt;

	// ReplaceOut.ar(in1, DelayN.ar(input1, maxDelay, dt.lag(0.01)));
	XOut.ar(in1, xfade, DelayN.ar(input1, maxDelay, dt.lag(0.01)));
}).add;


SynthDef(\bitDelayFX, {|in1, in2, gate = 1, fadeTime = 1|
	var frame = 4069;
	var rFrame = frame.reciprocal;
	var rSR = SampleRate.ir.reciprocal;
	var maxDelay = rSR * frame;

	var input1 = In.ar(in1) > 0;
	var input2 = In.ar(in2) > 0;

	var xfade = Env.asr(fadeTime, 1, fadeTime, 1).kr(2, gate);
	// the louder, the more delay
	var dt = RunningSum.ar(input2 > 0, frame) * rFrame * maxDelay; // ensure values between 0..maxDelay

	dt = xfade * dt;
	//ReplaceOut.ar(in1, DelayN.ar(input1, maxDelay, dt.lag(0.01)));
	XOut.ar(in1, xfade, DelayN.ar(input1, maxDelay, dt.lag(0.01)));
}).add;

SynthDef(\bitDelayFX_inv, {|in1, in2, gate = 1, fadeTime = 1|
	var frame = 4069;
	var rFrame = frame.reciprocal;
	var rSR = SampleRate.ir.reciprocal;
	var maxDelay = rSR * frame;

	var input1 = In.ar(in1) > 0;
	var input2 = In.ar(in2) > 0;

	var xfade = Env.asr(fadeTime, 1, fadeTime, 1).kr(2, gate);
	// the louder, the more delay
	var dt = maxDelay - (RunningSum.ar(input2 > 0, frame) * rFrame * maxDelay); // ensure values between 0..maxDelay
	dt = Line.kr(0, 1, 1) * dt;
	// ReplaceOut.ar(in1, DelayN.ar(input1, maxDelay, dt.lag(0.01)));
	XOut.ar(in1, xfade, DelayN.ar(input1, maxDelay, dt.lag(0.01)));
}).add;


SynthDef(\andFX, {|in1, in2, gate = 1, fadeTime = 1|
	var input1 = In.ar(in1) > 0;
	var input2 = In.ar(in2) > 0;
	var fx = (input1 + input2) > 1;
	// ReplaceOut.ar(in1, fx * 2 - 1)
	var xfade = Env.asr(fadeTime, 1, fadeTime, 1).kr(2, gate);
	XOut.ar(in1, xfade, fx * 2 - 1);
}).add;

SynthDef(\orFX, {|in1, in2, gate = 1, fadeTime = 1|
	var input1 = In.ar(in1) > 0;
	var input2 = In.ar(in2) > 0;
	var fx = (input1 + input2) > 0;
	// ReplaceOut.ar(in1, fx * 2 - 1)
	var xfade = Env.asr(fadeTime, 1, fadeTime, 1).kr(2, gate);
	XOut.ar(in1, xfade, fx * 2 - 1);
}).add;


SynthDef(\rotFX, {|in1, in2, gate = 1, fadeTime = 1|
	var input1 = In.ar(in1) > 0;
	var input2 = In.ar(in2) > 0;
	var amount = RunningSum.ar(input2, 1024) * 1024.reciprocal; // ensure values between 0..1
	var noise = WhiteNoise.ar(0.5, 0.5);

	var fx = Select.ar(noise > (amount * 0.01) , [input1,  input1.neg]);

	var xfade = Env.asr(fadeTime, 1, fadeTime, 1).kr(2, gate);
	XOut.ar(in1, xfade, fx);

	// ReplaceOut.ar(in1, fx)
}).add;

SynthDef(\rotFX_inv, {|in1, in2, gate = 1, fadeTime = 1|
	var input1 = In.ar(in1) > 0;
	var input2 = In.ar(in2) > 0;
	var amount = 1 - (RunningSum.ar(input2, 1024) * 1024.reciprocal); // ensure values between 0..1
	var noise = WhiteNoise.ar(0.5, 0.5);

	var fx = Select.ar(noise > (amount * 0.01), [input1,  input1.neg]);

	var xfade = Env.asr(fadeTime, 1, fadeTime, 1).kr(2, gate);
	XOut.ar(in1, xfade, fx);
	// ReplaceOut.ar(in1, fx)
}).add;

q = q ? ();
q.synthNames = ();
q.synthNames[0] = \bitDelayFX;
q.synthNames[1] = \bitDelayFX_inv;
q.synthNames[2] = \delayFX;
q.synthNames[3] = \delayFX_inv;
q.synthNames[4] = \rotFX;
q.synthNames[5] = \rotFX_inv;
q.synthNames[6] = \andFX;
q.synthNames[7] = \orFX;
)