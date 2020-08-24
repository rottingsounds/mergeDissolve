(
SynthDef(\map2fb, {|from = 0, to = 2|
	var input = InFeedback.ar(from, 2);
	// var fx = DelayN.ar(input, s.options.blockSize / s.sampleRate, s.options.blockSize / s.sampleRate);

	Out.ar(to, input);
}).add;
SynthDef(\map2, {|from = 0, to = 2|
	Out.ar(to, In.ar(from, 2));
}).add;

SynthDef(\tester, {|out| Out.ar(out, Impulse.ar(100)!2)}).add
)


q = ();

q.b1 = Bus.audio(s, 2);
q.b2 = Bus.audio(s, 2);

q.b2.scope
q.b1.scope

q.in = Synth(\tester, [\out, q.b1]);
q.in.free



q.cable = Synth(\map2, [\from, q.b1, \to, q.b2], q.in, \addAfter);
q.fb = Synth(\map2fb, [\from, q.b2, \to, q.b1], q.in, \addBefore);
q.fb.free

q.listen = Synth(\map2, [\from, q.b2, \to, 0], q.cable, \addAfter)
q.listen.free

q.fb.free

y.free




s.queryAllNodes
In

