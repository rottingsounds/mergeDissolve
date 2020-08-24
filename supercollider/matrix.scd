
// ServerOptions.devices
/*
s.queryAllNodes
// */


(
s.options.device = "Babyface (23181487)";
s.options.sampleRate = 192000;
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

	q.hwlocalKathrinOut = Bus(\audio, 2, 2, s);

	q.hwThomasIn = Bus(\audio, s.options.numOutputBusChannels + q.thomasInIdx, 2, s);
	q.hwThomasOut = Bus(\audio, 0 + q.thomasOutIdx, 2, s);


	// input channels
	q.input = ();
	q.input.all     = Bus.audio(s, 8);
	q.input.efx     = q.input.all.subBus(0, 2);
	q.input.thomas  = q.input.all.subBus(2, 2);
	q.input.kathrin = q.input.all.subBus(4, 2);
	q.input.local   = q.input.all.subBus(6, 2);



	// output channels
	q.output = ();
	q.output.all     = Bus.audio(s, 8);
	q.output.efx     = q.output.all.subBus(0, 2);
	q.output.thomas  = q.output.all.subBus(2, 2);
	q.output.kathrin = q.output.all.subBus(4, 2);
	q.output.local   = q.output.all.subBus(6, 2);


	// routing
	SynthDef(\map1, {|from = 0, to = 2|
		Out.ar(to, In.ar(from, 1));
	}).add;
	SynthDef(\map2, {|from = 0, to = 2|
		Out.ar(to, In.ar(from, 2));
	}).add;
	SynthDef(\map4, {|from = 0, to = 2|
		Out.ar(to, In.ar(from, 4));
	}).add;
	SynthDef(\map8, {|from = 0, to = 2|
		Out.ar(to, In.ar(from, 8));
	}).add;


	SynthDef(\map2_dsm, {|from = 0, to = 2|
		var input = In.ar(from, 2);
		var fx = DSM2.ar(input, \bipolar);

		Out.ar(to, fx);
	}).add;


	SynthDef(\map2_lp, {|from = 0, to = 2|
		var input = In.ar(from, 2);
		var lpFreq = 24000; // nyquist of 48k
		// var fx = LPF.ar(input, lpFreq);
		var fx = DSM2PCM.ar(input.clip(-1, 1), lpFreq);

		Out.ar(to, fx);
	}).add;

	SynthDef(\map2_fb, {|from = 0, to = 2|
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

			var input1 = In.ar(in1);
			var input2 = In.ar(in2);

			// the louder, the less delay
			var dt = RunningSum.ar(input2 > 0, frame) * rFrame * maxDelay; // ensure values between 0..maxDelay
			ReplaceOut.ar(in1, DelayN.ar(input1, maxDelay, dt));
		}).add;

		SynthDef(\delayFX_inv, {|in1, in2|
			var frame = 2048;
			var rFrame = frame.reciprocal;
			var rSR = s.sampleRate.reciprocal;
			var maxDelay = 1;

			var input1 = In.ar(in1);
			var input2 = In.ar(in2);

			// the louder, the less delay
			var dt = maxDelay - (RunningSum.ar(input2 > 0, frame) * rFrame * maxDelay); // ensure values between 0..maxDelay
			ReplaceOut.ar(in1, DelayN.ar(input1, maxDelay, dt));
		}).add;


		SynthDef(\bitDelayFX, {|in1, in2|
			var frame = 4069;
			var rFrame = frame.reciprocal;
			var rSR = s.sampleRate.reciprocal;
			var maxDelay = rSR * frame;

			var input1 = In.ar(in1) > 0.5;
			var input2 = In.ar(in2) > 0.5;

			// the louder, the more delay
			var dt = RunningSum.ar(input2 > 0, frame) * rFrame * maxDelay; // ensure values between 0..maxDelay
			ReplaceOut.ar(in1, DelayN.ar(input1, maxDelay, dt));
		}).add;

		SynthDef(\bitDelayFX_inv, {|in1, in2|
			var frame = 4069;
			var rFrame = frame.reciprocal;
			var rSR = s.sampleRate.reciprocal;
			var maxDelay = rSR * frame;

			var input1 = In.ar(in1);
			var input2 = In.ar(in2);

			// the louder, the more delay
			var dt = maxDelay - (RunningSum.ar(input2 > 0, frame) * rFrame * maxDelay); // ensure values between 0..maxDelay
			ReplaceOut.ar(in1, DelayN.ar(input1, maxDelay, dt));
		}).add;


		SynthDef(\andFX, {|in1, in2|
			var input1 = In.ar(in1) > 0;
			var input2 = In.ar(in2) > 0;
			var fx = (input1 + input2) > 1;
			ReplaceOut.ar(in1, fx * 2 - 1)
		}).add;

		SynthDef(\orFX, {|in1, in2|
			var input1 = In.ar(in1) > 0;
			var input2 = In.ar(in2) > 0;
			var fx = (input1 + input2) > 0;
			ReplaceOut.ar(in1, fx * 2 - 1)
		}).add;


		SynthDef(\rotFX, {|in1, in2|
			var input1 = In.ar(in1) > 0;
			var input2 = In.ar(in2) > 0;
			var amount = RunningSum.ar(input2, 1024) * 1024.reciprocal; // ensure values between 0..1
			var noise = WhiteNoise.ar(0.5, 0.5);

			var fx = Select.ar(noise > amount, [input1,  input1.neg]);
			ReplaceOut.ar(in1, fx)
		}).add;

		SynthDef(\rotFX_inv, {|in1, in2|
			var input1 = In.ar(in1) > 0;
			var input2 = In.ar(in2) > 0;
			var amount = 1 - (RunningSum.ar(input2, 1024) * 1024.reciprocal); // ensure values between 0..1
			var noise = WhiteNoise.ar(0.5, 0.5);

			var fx = Select.ar(noise > amount, [input1,  input1.neg]);
			ReplaceOut.ar(in1, fx)
		}).add;

		q.synthNames = ();
		q.synthNames[0] = \delayFX_inv;
		q.synthNames[1] = \bitDelayFX_inv;
		q.synthNames[2] = \andFX;
		q.synthNames[3] = \orFX;
		q.synthNames[4] = \rotFX_inv;
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
	q.mappers.efxFB = q.mappers.efxFB ?? {Synth(\map2_fb, [\from, q.output.efx.index, \to, q.input.efx.index], q.inGroup)};
	q.mappers.localIn = q.mappers.localIn ?? {Synth(\map2_dsm, [\from, q.hwLocalIn.index, \to, q.input.local.index], q.mappers.efxFB, \addAfter)};

	q.mappers.thomasIn = q.mappers.thomasIn ?? {Synth(\map2, [\from, q.hwThomasIn.index, \to, q.input.thomas.index], q.mappers.efxFB, \addAfter)};


	q.mappers.localOut = q.mappers.localOut ?? {Synth(\map2_lp, [\from, q.output.local.index, \to, q.hwLocalOut.index], q.outGroup)};
	q.mappers.localKathrinOut = q.mappers.localKathrinOut ?? {Synth(\map2_lp, [\from, q.output.kathrin.index, \to, q.hwlocalKathrinOut.index], q.outGroup)};

	q.mappers.thomasOut = q.mappers.thomasOut ?? {Synth(\map2, [\from, q.output.thomas.index, \to, q.hwThomasOut.index], q.outGroup)};
}
)




(
(
q.efxLoVal = 2;
q.efxHiVal = 13;
q.matrixLoVal = 3;
q.matrixHiVal = 13;
// q.monome.ledall(0);
q.efxLoVals = [
	false!8,
	false!8,
	true!8,
	true!8,
	true!8,
	true!8,
	true!8,
	true!8,
].flop;

q.matrixLoVals = [
	false!8,
	false!8,
	true!8,
	true!8,
	false!8,
	false!8,
	false!8,
	false!8,
];

8.do{|i|
	q.matrixLoVals[i][i] = q.matrixLoVals[i][i].not;
};


q.monome.levmap(0, 0, q.efxLoVals.flat.collect{|isHi| q.efxLoVal + isHi.if({2}, {0})});
q.monome.levmap(0, 8, q.matrixLoVals.flat.collect{|isHi| q.matrixLoVal + isHi.if({2}, {0})});

q.updateEfxKey = {|q, c, r, pressed|
	var offset = q.efxLoVals[r][c].if({2}, {0});
	pressed.if({
		q.monome.levset(c, r, q.efxHiVal + offset);
	}, {
		q.monome.levset(c, r, q.efxLoVal + offset);
	});
};
q.updateMatrixKey = {|q, c, r, pressed|
	var offset = q.matrixLoVals[r][c].if({2}, {0});
	pressed.if({
		q.monome.levset(c, r+8, q.matrixHiVal + offset);
	}, {
		q.monome.levset(c, r+8, q.matrixLoVal + offset);
	});
};

);


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
				// q.monome.levset(c, r+8, q.matrixLoVal)
				q.updateMatrixKey(c, r, false);
			}, {
				// create synth
				[\map, \from, r, \to, c].postln;
				q.matrix[c][r] = Synth(\map1, [\from, q.input.all.index + c, \to, q.output.all.index + r], q.matrixGroup);
				// q.monome.levset(c, r+8, q.matrixHiVal)
				q.updateMatrixKey(c, r, true);
			});
		}, {
		// upper part:
		// efx connections
			(q.efxChains[c][r].notNil).if({
				q.efxChains[c][r].free;
				q.efxChains[c][r] = nil;
				// q.monome.levset(c, r, q.efxLoVal)
				q.updateEfxKey(c, r, false);
			}, {
				var target = q.efxSubGroups[r];
				var in1 = q.input.all.index + c;
				var in2 = c.even.if({in1+1}, {in1-1}); // always pairs
				q.efxChains[c][r] = Synth(q.synthNames[r], [\in1, in1, \in2, in2], target, \addToHead);
				// q.monome.levset(c, r, q.efxHiVal)
				q.updateEfxKey(c, r, true);
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
		Silent.ar, // LFPulse.ar(100), // efxFB
		Silent.ar, // LFPulse.ar(230), // efxFB
		WhiteNoise.ar.range(0, 1) > 0.5, // thomas
		SinOsc.ar(230), // thomas
		SinOsc.ar(140), // kathrin
		SinOsc.ar(15), // kathrin
		Silent.ar, // LFPulse.ar(1), //local
		Silent.ar, // LFPulse.ar(15, 0, 0.12), // local
	];

	DSM2PCM.ar(src * 2 - 1, 12000)
})
)

Ndef(\inTest).edit
Ndef(\inTest).play(q.input.all, 8, q.inGroup)
Ndef(\inTest).stop
Ndef(\inTest).scope
Ndef(\inTest).play


// x = Synth(\inTest, target: q.inGroup, addAction: \addToTail);
// x.free


q.output.all.scope

q.input.all.scope


s.scope