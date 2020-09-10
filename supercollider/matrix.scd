// Till's code for the 2020 performance
// "merge dissolve", by Till Bovermann, Thomas Grill, Kathrin Hunze
// performed on 10.9.2020 at sound campus, ars electronica festival linz
// funded through rotting sounds as project AR 445-G24 by the Austrian Science Fund (FWF)
// for https://www.dieangewandte.at/


// ServerOptions.devices
/*
s.queryAllNodes
Server.killAll
// */
ServerOptions.devices

(
// s.options.device = "MixPre-6 II";
s.options.device = "Babyface (23181487)";
s.options.memSize = 16*8192;
s.options.sampleRate = 192000;
s.options.numOutputBusChannels = 14;
s.options.numInputBusChannels = 12;
s.waitForBoot{
	s.latency = nil;
	s.plotTree;

	q = ();

	q.monome = MonoM(\monome, 90).useDevice(0);


	q.mapFadeTime = 2;
	q.efxFadeTime = 5;

	q.thomasInIdx = 2;
	q.thomasOutIdx = 4;

	// hardware channels
	q.hwLocalIn = Bus(\audio, s.options.numOutputBusChannels, 2, s);
	q.hwLocalOut = Bus(\audio, 0, 2, s);

	// q.hwlocalKathrinOut = Bus(\audio, 2, 2, s);
	q.hwlocalKathrinOut = q.hwLocalOut;

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

	SynthDef(\map1_xfade, {|from = 0, to = 2, gate = 1, fadeTime = 1|
		var xfade = Env.asr(fadeTime, 0.75, fadeTime, 1).kr(2, gate);
		var oldSignal = In.ar(to, 1);
		var newSignal = In.ar(from, 1);
		newSignal = DSMAdd.ar(oldSignal, newSignal);
		XOut.ar(to, xfade, newSignal);

		// Out.ar(to, In.ar(from, 1) * xfade);
	}).add;

	SynthDef(\map2_dsm, {|from = 0, to = 2|
		var input = In.ar(from, 2);
		var fx = DSM2.ar(input, \bipolar);

		Out.ar(to, fx);
	}).add;


	SynthDef(\map2_lp, {|from = 0, to = 2, amp = 1|
		var input = In.ar(from, 2);
		// var lpFreq = 24000; // nyquist of 48k
		var lpFreq = 20000;
		// var fx = LPF.ar(input, lpFreq);
		var fx = LeakDC.ar(DSM2PCM.ar(input.clip(-1, 1), lpFreq));

		Out.ar(to, fx * amp);
	}).add;

	SynthDef(\map4_lp, {|from = 0, to = 2, amp = 1|
		var input = In.ar(from, 4);
		// var lpFreq = 24000; // nyquist of 48k
		var lpFreq = 20000;
		// var fx = LPF.ar(input, lpFreq);
		var fx = LeakDC.ar(DSM2PCM.ar(input.clip(-1, 1), lpFreq));

		Out.ar(to, fx * amp);
	}).add;

	SynthDef(\map2_fb, {|from = 0, to = 2|
		var input = InFeedback.ar(from, 2) > 0.5;
		// TODO: might get really big... best to limit somewhere?
		Out.ar(to, input);
	}).add;

	(
		SynthDef(\delayFX, {|in1, in2, gate = 1, fadeTime = 1|
			var frame = 2048;
			var rFrame = frame.reciprocal;
			var rSR = s.sampleRate.reciprocal;
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
			var rSR = s.sampleRate.reciprocal;
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
			var rSR = s.sampleRate.reciprocal;
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
			var rSR = s.sampleRate.reciprocal;
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

		q.synthNames = ();
		q.synthNames[0] = \bitDelayFX;
		q.synthNames[1] = \bitDelayFX_inv;
		q.synthNames[2] = \delayFX;
		q.synthNames[3] = \delayFX_inv;
		q.synthNames[4] = \rotFX;
		q.synthNames[5] = \rotFX_inv;
		q.synthNames[6] = \andFX;
		q.synthNames[7] = \orFX;
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


(
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
				q.matrix[c][r].set(\gate, 0);
				q.matrix[c][r] = nil;
				// q.monome.levset(c, r+8, q.matrixLoVal)
				q.updateMatrixKey(c, r, false);
			}, {
				// create synth
				[\map, \from, r, \to, c].postln;
				q.matrix[c][r] = Synth(\map1_xfade, [\from, q.input.all.index + c, \to, q.output.all.index + r, \fadeTime, q.mapFadeTime], q.matrixGroup);
				// q.monome.levset(c, r+8, q.matrixHiVal)
				q.updateMatrixKey(c, r, true);
			});
		}, {
			// upper part:
			// efx connections
			(q.efxChains[c][r].notNil).if({
				q.efxChains[c][r].set(\gate, 0);
				q.efxChains[c][r] = nil;
				// q.monome.levset(c, r, q.efxLoVal)
				q.updateEfxKey(c, r, false);
			}, {
				var target = q.efxSubGroups[r];
				var in1 = q.input.all.index + c;
				var in2 = c.even.if({in1+1}, {in1-1}); // always pairs

				[q.synthNames[r], [\in1, in1 - q.input.all.index, \in2, in2- q.input.all.index]].postln;

				q.efxChains[c][r] = Synth(q.synthNames[r], [\in1, in1, \in2, in2, \fadeTime, q.efxFadeTime], target, \addToHead);
				// q.monome.levset(c, r, q.efxHiVal)
				q.updateEfxKey(c, r, true);
			});
		});
	});

}, "/monome/grid/key");
);
)


Ndef(\inTest).clear


(
Ndef('inTest').fadeTime = 10;

// Ndef(\inTest).fadeTime = 0;
Ndef(\inTest).addSpec(
	\freq1, \freq,
	\freq2, \freq,
	\freq3, \freq,
	\freq4, \freq,
	\freq5, \freq,
	\freq6, \freq,
	\freq7, \freq,
	\freq8, \freq,
	\amp1, \amp,
	\amp2, \amp,
	\amp3, \amp,
	\amp4, \amp,
	\amp5, \amp,
	\amp6, \amp,
	\amp7, \amp,
	\amp8, \amp,
	\idx1, [0, 4],
	\idx2, [0, 4],
	\idx3, [0, 4],
	\idx4, [0, 4],
	\idx5, [0, 4],
	\idx6, [0, 4],
	\idx7, [0, 4],
	\idx8, [0, 4]
);
Ndef(\inTest, {
	var freqs = [
		\freq1.kr(100),
		\freq2.kr(100),
		\freq3.kr(100),
		\freq4.kr(100),
		\freq5.kr(100),
		\freq6.kr(100),
		\freq7.kr(100),
		\freq8.kr(100),
	];

	var amps = [
		\amp1.kr(1),
		\amp2.kr(1),
		\amp3.kr(1),
		\amp4.kr(1),
		\amp5.kr(1),
		\amp6.kr(1),
		\amp7.kr(1),
		\amp8.kr(1),
	];

	var sndIdxs = [
		\idx1.kr(0),
		\idx2.kr(0),
		\idx3.kr(0),
		\idx4.kr(0),
		\idx5.kr(0),
		\idx6.kr(0),
		\idx7.kr(0),
		\idx8.kr(0),
	];

	var src = [freqs, amps, sndIdxs].flop.collect{|args, i|
		var freq, amp, sndIdx, snd;
		# freq, amp, sndIdx = args;

		snd = SelectX.ar(sndIdx, [
			SinOscFB.ar(freq, 0.3),
			LFTri.ar(freq),
			LFPulse.ar(freq, 0, 0.3),
			Impulse.ar(freq)
		]);

		snd * amp * AmpCompA.kr(freq, 50);

	};

	// src = src * ({LFNoise1.kr(rrand(0.05, 0.4)).range(0.5, 1)}!8);

	src = src.tanh;
	DSM2.ar(src, \bipolar)
})
)

(
Ndef('inTest').xset(
	'freq1', 500.0,
	'freq2', 501.1,
	'freq3', 1000.2,
	'freq4', 1000.2,
	'freq5', 1501.0,
	'freq6', 1500.1,
	'freq7', 8000.0,
	'freq8', 8030.1,
	'idx2', 0.4021164021164,
	'idx1', 0.65608465608466,
	'idx7', 2.7936507936508,
	'idx5', 2.8994708994709,
	'idx3', 4.0,
	'idx4', 4.0,
	'idx8', 2.2433862433862,
	'idx6', 2.1587301587302,
	\amp1, 1,
	\amp2, 1,
	\amp3, 1,
	\amp4, 1,
	\amp5, 1,
	\amp6, 1,
	\amp7, 1,
	\amp8, 1,
);
)


(
// low
Ndef('inTest').xset(
	'freq1', 50.0,
	'freq2', 50.1,
	\freq2, 100,
	'freq4', 100.2,
	'freq5', 150.0,
	'freq6', 150.1,
	'freq7', 800.0,
	'freq8', 800.1,
	'idx1', 0.4021164021164,
	'idx2', 0.65608465608466,
	'idx3', 2.7936507936508,
	'idx4', 2.8994708994709,
	'idx5', 4.0,
	'idx6', 4.0,
	'idx7', 2.2433862433862,
	'idx8', 2.1587301587302,
	\amp1, 1,
	\amp2, 1,
	\amp3, 1,
	\amp4, 1,
	\amp5, 1,
	\amp6, 1,
	\amp7, 1,
	\amp8, 1,
);
)


(
// highJosh
Ndef('inTest').xset(
	'freq1', 1120,
	'freq2', 1199.1,
	\freq2, 1214,
	'freq4', 1441.2,
	'freq5', 1981.0,
	'freq6', 1150.1,
	'freq7', 850.0,
	'freq8', 8500.1,
	'idx1', 0.1,
	'idx2', 0.5608466,
	'idx3', 1.507936508,
	'idx4', 1.8994708994709,
	'idx5', 3.0,
	'idx6', 2.0,
	'idx7', 1.2433862433862,
	'idx8', 0.1587301587302,
	\amp1, 1,
	\amp2, 1,
	\amp3, 1,
	\amp4, 1,
	\amp5, 1,
	\amp6, 1,
	\amp7, 1,
	\amp8, 1,
);
)


(
// blink_7
Ndef('inTest').xset(
	'freq1', 120,
	'freq2', 199.1,
	\freq2, 114,
	'freq4', 441.2,
	'freq5', 981.0,
	'freq6', 115.1,
	'freq7', 850.0,
	'freq8', 850.1,
	'idx1', 0.1,
	'idx2', 0.5608466,
	'idx3', 4.507936508,
	'idx4', 3.8994708994709,
	'idx5', 2.0,
	'idx6', 1.0,
	'idx7', 0.2433862433862,
	'idx8', 0,
	\amp1, 1,
	\amp2, 1,
	\amp3, 1,
	\amp4, 1,
	\amp5, 1,
	\amp6, 1,
	\amp7, 1,
	\amp8, 1,
);
)

// (
// Ndef(\inTest).fadeTime = 20;
// Ndef(\inTest, {
// 	// Out.ar(q.input.all, Silent.ar + ({|i|i+1}!8 / 10))
// 	// var trigs = Dust.kr(LFNoise1.kr(rand(0.1, 10.5)).range(0.1, 1));
// 	var freqs = {LFNoise2.kr(LFNoise1.kr(rand(0.1, 0.05)).range(1, 5)).exprange(*([1.0, 4.0] * rrand(100.0, 200)))}!8;
// 	var src = [
// 		SinOsc.ar(1120), // thomas
// 		SinOsc.ar(1199), // thomas
// 		SinOsc.ar(1214), // thomas
// 		SinOsc.ar(1441), // thomas
// 		SinOsc.ar(1981), // kathrin
// 		SinOsc.ar(1150.2), // kathrin
// 		Silent.ar, // LFPulse.ar(1), //local
// 		Silent.ar, // LFPulse.ar(15, 0, 0.12), // local
// 	];
//
// 	src = src * ({LFNoise1.kr(rrand(0.05, 0.4)).range(0.1, 1)}!8);
//
// 	DSM2.ar(src, \bipolar)
// })
// )

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