
// ServerOptions.devices
/*
s.queryAllNodes
// */


(
s.options.device = "Babyface (23181487)";
s.options.numOutputBusChannels = 14;
s.options.numInputBusChannels = 12;
s.waitForBoot{
	s.latency = nil;
	s.plotTree;

	q = ();

	q.monome = MonoM(\monome, 90).useDevice(0);



	q.thomasInIdx = 2;
	q.thomasOutIdx = 4;

	// hardware channels
	q.hwLocalIn = Bus(\audio, s.options.numOutputBusChannels, 2, s);
	q.hwLocalOut = Bus(\audio, 0, 2, s);

	q.hwThomasIn = Bus(\audio, s.options.numOutputBusChannels + q.thomasInIdx, 2, s);
	q.hwThomasOut = Bus(\audio, 0 + q.thomasOutIdx, 2, s);


	// input channels
	q.input = ();
	q.input.all     = Bus.audio(s, 8);
	q.input.efx     = q.input.all.subBus(0, 2);
	q.input.kathrin = q.input.all.subBus(2, 2);
	q.input.thomas  = q.input.all.subBus(4, 2);
	q.input.local   = q.input.all.subBus(6, 2);



	// output channels
	q.output = ();
	q.output.all     = Bus.audio(s, 8);
	q.output.efx     = q.output.all.subBus(0, 2);
	q.output.kathrin = q.output.all.subBus(2, 2);
	q.output.thomas  = q.output.all.subBus(4, 2);
	q.output.local   = q.output.all.subBus(6, 2);


	// routing
	SynthDef(\map1, {|from = 0, to = 2|
		Out.ar(to, In.ar(from, 1) > 0.5);
	}).add;
	SynthDef(\map2, {|from = 0, to = 2|
		Out.ar(to, In.ar(from, 2) > 0.5);
	}).add;
	SynthDef(\map4, {|from = 0, to = 2|
		Out.ar(to, In.ar(from, 4) > 0.5);
	}).add;
	SynthDef(\map8, {|from = 0, to = 2|
		Out.ar(to, In.ar(from, 8) > 0.5);
	}).add;

	SynthDef(\map2lp, {|from = 0, to = 2|
		var input = In.ar(from, 2) > 0.5;
		var fx = LPF.ar(input, 48000/2);

		Out.ar(to, fx);
	}).add;

	SynthDef(\map2fb, {|from = 0, to = 2|
		var input = InFeedback.ar(from, 2) > 0.5;
		// TODO: might get really big... best to limit somewhere?
		Out.ar(to, input);
	}).add;

	(
		SynthDef(\delayFX, {|in1, in2|
			var frame = 2048;
			var rFrame = frame.reciprocal;
			var rSR = s.sampleRate.reciprocal;
			var maxDelay = 1;

			var input1 = In.ar(in1) > 0.5;
			var input2 = In.ar(in2) > 0.5;
			var dt = RunningSum.ar(input2, frame) * rFrame * maxDelay; // ensure values between 0..maxDelay
			ReplaceOut.ar(in1, DelayN.ar(input1, maxDelay, dt));
		}).add;

		SynthDef(\bitDelayFX, {|in1, in2|
			var frame = 4069;
			var rFrame = frame.reciprocal;
			var rSR = s.sampleRate.reciprocal;
			var maxDelay = rSR * frame;

			var input1 = In.ar(in1) > 0.5;
			var input2 = In.ar(in2) > 0.5;
			var dt = RunningSum.ar(input2, frame) * rFrame * maxDelay; // ensure values between 0..maxDelay
			ReplaceOut.ar(in1, DelayN.ar(input1, maxDelay, dt));
		}).add;

		SynthDef(\andFX, {|in1, in2|
			var input1 = In.ar(in1) > 0.5;
			var input2 = In.ar(in2) > 0.5;
			var fx = (input1 + input2) > 1;
			ReplaceOut.ar(in1, fx)
		}).add;

		SynthDef(\orFX, {|in1, in2|
			var input1 = In.ar(in1) > 0.5;
			var input2 = In.ar(in2) > 0.5;
			var fx = (input1 + input2) > 0;
			ReplaceOut.ar(in1, fx)
		}).add;


		SynthDef(\rotFX, {|in1, in2|
			var input1 = In.ar(in1) > 0.5;
			var input2 = In.ar(in2) > 0.5;
			var amount = RunningSum.ar(input2, 1024) * 1024.reciprocal; // ensure values between 0..1
			var noise = WhiteNoise.ar(0.5, 0.5);

			var fx = Select.ar(noise > amount, [input1,  1-input1]);
			ReplaceOut.ar(in1, fx)
		}).add;

		q.synthNames = ();
		q.synthNames[0] = \delayFX;
		q.synthNames[1] = \bitDelayFX;
		q.synthNames[2] = \andFX;
		q.synthNames[3] = \orFX;
		q.synthNames[4] = \rotFX;
		q.synthNames[5] = \bitDelayFX;
		q.synthNames[6] = \delayFX;
		q.synthNames[7] = \rotFX;
	);

	s.sync;

	q.inGroup = q.inGroup ?? {Group(s, \addToHead)};
	q.efxGroup = q.efxGroup ?? {Group(q.inGroup, \addAfter)};
	q.efxSubGroups = q.efxSubGroups.isNil.if{
		8.collect{
			Group(q.efxGroup, \addToTail)
		}
	};

	q.matrixGroup = q.matrixGroup ?? {Group(q.efxGroup, \addAfter)};
	q.outGroup = q.outGroup ?? {Group(q.matrixGroup, \addAfter)};

	q.mappers = q.mappers ? ();
	q.mappers.efxFB = q.mappers.efxFB ?? {Synth(\map2fb, [\from, q.output.efx.index, \to, q.input.efx.index], q.inGroup)};
	q.mappers.localIn = q.mappers.localIn ?? {Synth(\map2, [\from, q.hwLocalIn.index, \to, q.input.local.index], q.mappers.efxFB, \addAfter)};

	q.mappers.thomasIn = q.mappers.thomasIn ?? {Synth(\map2, [\from, q.hwThomasIn.index, \to, q.input.thomas.index], q.mappers.efxFB, \addAfter)};


	q.mappers.localOut = q.mappers.thomasOut ?? {Synth(\map2lp, [\from, q.output.local.index, \to, q.hwLocalOut.index], q.outGroup)};

	// TODO - FIXME \map2lp >> \map2
	q.mappers.thomasOut = q.mappers.thomasOut ?? {Synth(\map2lp, [\from, q.output.thomas.index, \to, q.hwThomasOut.index], q.outGroup)};
}
)




(
q.efxLoVal = 5;
q.efxHiVal = 15;
q.matrixLoVal = 3;
q.matrixHiVal = 15;
// q.monome.ledall(0);
q.monome.levmap(0, 0, q.efxLoVal!64);
q.monome.levmap(0, 8, q.matrixLoVal !64);

q.matrix.notNil.if{
	q.matrix.flat.do(_.free); // reset matrix
};
q.matrix = nil!8!8;

q.efxChains.notNil.if{
	q.efxChains.flat.do(_.free); // reset matrix
};
q.efxChains = nil!8!8;



OSCdef.newMatching(\matrix, {|msg, time, addr, recvPort|
	var name, r, c, v;
	#name, c, r, v = msg;

	(v == 1).if({ // keyDown
		// [r, c].postln;
		(r > 7).if({

		// lower part:
		// matrix connections
		r = r % 8; // adjust row to be in range [0..7]

			(q.matrix[c][r].notNil).if({
				 // free synth
				q.matrix[c][r].free;
				q.matrix[c][r] = nil;
				q.monome.levset(c, r+8, q.matrixLoVal)
			}, {
				// create synth
				[\map, \from, r, \to, c].postln;
				q.matrix[c][r] = Synth(\map1, [\from, q.input.all.index + r, \to, q.output.all.index + c], q.matrixGroup);
				q.monome.levset(c, r+8, q.matrixHiVal)
			});
		}, {
		// upper part:
		// efx connections
			(q.efxChains[c][r].notNil).if({
				q.efxChains[c][r].free;
				q.efxChains[c][r] = nil;
				q.monome.levset(c, r, q.efxLoVal)
			}, {
				var target = q.efxSubGroups[r];
				var in1 = q.input.all.index + c;
				var in2 = c.even.if({in1+1}, {in1-1}); // always pairs
				q.efxChains[c][r] = Synth(q.synthNames[r], [\in1, in1, \in2, in2], target, \addToHead);
				q.monome.levset(c, r, q.efxHiVal)
			});
		});
	});

}, "/monome/grid/key");
)



Ndef(\inTest).clear

(
Ndef(\inTest, {
	// Out.ar(q.input.all, Silent.ar + ({|i|i+1}!8 / 10))
	var src = [
		LFPulse.ar(100),
		LFPulse.ar(230),
		WhiteNoise.ar.range(0, 1) > 0.5,
		WhiteNoise.ar.range(0, 1) > 0.2,
		LFPulse.ar(14),
		LFPulse.ar(15),
		LFPulse.ar(1),
		LFPulse.ar(15, 0, 0.12),
	];

	src
})
)

Ndef(\inTest).edit
Ndef(\inTest).play(q.input.all, 8, q.inGroup)
Ndef(\inTest).stop
Ndef(\inTest).scope


// x = Synth(\inTest, target: q.inGroup, addAction: \addToTail);
// x.free


q.output.all.scope

q.input.all.scope