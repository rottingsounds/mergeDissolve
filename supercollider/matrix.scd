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


		////////////////////// SynthDefs ////////////////////////
	// efx
	(thisProcess.nowExecutingPath.dirname +/+ "efx.scd").load;

	// sonify
	(thisProcess.nowExecutingPath.dirname +/+ "sonify.scd").load;


	// routing

	[1, 2, 4, 8].do{|i|
		SynthDef("map"++i, {|from = 0, to = 2|
			Out.ar(to, In.ar(from, i));
		}).add;

		SynthDef("map%_xfade".format(i), {|from = 0, to = 2, gate = 1, fadeTime = 1|
			var xfade = Env.asr(fadeTime, 0.75, fadeTime, 1).kr(2, gate);
			var oldSignal = In.ar(to, i);
			var newSignal = In.ar(from, i);
			newSignal = DSMAdd.ar(oldSignal, newSignal);
			XOut.ar(to, xfade, newSignal);

			// Out.ar(to, In.ar(from, i) * xfade);
		}).add;

		SynthDef("map%_dsm".format(i), {|from = 0, to = 2|
			var input = In.ar(from, i);
			var fx = DSM2.ar(input, \bipolar);

			Out.ar(to, fx);
		}).add;

		SynthDef("map%_lp".format(i), {|from = 0, to = 2, amp = 1, lpFreq = 20000|
			var input = In.ar(from, i);
			// var lpFreq = 24000; // nyquist of 48k
			// var fx = LPF.ar(input, lpFreq);
			var fx = LeakDC.ar(DSM2PCM.ar(input.clip(-1, 1), lpFreq));

			Out.ar(to, fx * amp);
		}).add;

		// SynthDef("map%_fb".format(i), {|from = 0, to = 2|
		// 	var input = InFeedback.ar(from, i) > 0.5;
		// 	// TODO: might get really big... best to limit somewhere?
		// 	Out.ar(to, input);
		// }).add;

	};



	(
		SynthDef(\map8to4_spatialLp, {|from = 0, to = 2, amp = 1, lpFreq = 20000, trigFreq = 10, id = 0|
			var spreads, turns, amps, brightnesses, balances;

			var input = In.ar(from, 8);
			var pcm8chan = LeakDC.ar(DSM2PCM.ar(input.clip(-1, 1), lpFreq));

			// 4 2chans with volume
			var srcs = pcm8chan.clump(2) * [0.1, 0.3, 0.5, 1];


			# amps, brightnesses, spreads, turns = srcs.collect{|src|
				var in = src.sum;
				var br, amp, spread, turn;

				br = LPF.ar(ZeroCrossing.ar(in), 1000);
				// br = A2K.kr(br) * (SampleRate.ir*0.5).reciprocal; // in case of fire
				br = br * (SampleRate.ir*0.5).reciprocal * 5;
				// br = max(min(br.log10, 0)/3+1, 0);
				br = br.clip(0, 1);

				amp = Amplitude.ar(in);
				// amp = A2K.kr(amp); // in case of fire
				amp = (amp*8).tanh;

				spread = 1-amp.lag(0.1, 1);
				turn = br * 2; // 2 turns

				[amp, br, spread, turn];
			}.flop;


			// brightnesses.poll;
			srcs = srcs.collect{|src, i|
				SplayAz.ar(4, src, spreads[i], center: turns[i])
			};

			balances = [[0, 2], [1, 3]].collect{|ids|
				var a, b;

				#a,b = ids;
				a = amps[a];
				b = amps[b];

				(a - b).linlin(-1, 1, 0, 1);

			};
			// amps.poll;

			SendReply.kr(Impulse.kr(trigFreq),
				cmdName: '/analysis',
				values: [amps, brightnesses].flop.flat ++ balances
			);

			// collapse channels
			srcs = srcs.sum;

			Out.ar(to, srcs * amp);
		}).add;
	);

	/*
	q.mappers.spatialMixer.free;
	q.mappers.spatialMixer =
		Synth(\map8to4_spatialLp, [
			\from, q.matrixOutBus.all,
			\to, q.hwLocalOutBus
	], q.outGroup);
	*/

	s.sync;


	//////// Buses
	// hardware channels
	q.hwLocalInBus = Bus(\audio, s.options.numOutputBusChannels, 2, s);
	q.hwLocalOutBus = Bus(\audio, 0, 4, s);

	// q.hwLocalKathrinOutBus = Bus(\audio, 2, 2, s);
	// q.hwLocalKathrinOutBus = q.hwLocalOutBus;

	q.hwThomasInBus = Bus(\audio, s.options.numOutputBusChannels + q.thomasInIdx, 2, s);
	q.hwThomasOutBus = Bus(\audio, 0 + q.thomasOutIdx, 2, s);


	// input channels to efx section,
	q.efxBus = ();
	q.efxBus.all     = Bus.audio(s, 8);
	q.efxBus.thomas  = q.efxBus.all.subBus(0, 2);
	q.efxBus.kathrin = q.efxBus.all.subBus(2, 2);
	q.efxBus.local   = q.efxBus.all.subBus(4, 4);

	// efx are replacing signals on bus, so efxBus is also matrixInBus
	q.matrixInBus = q.efxBus;

	// efx section outputs are routed to matrix input via controller

	// matrix output channels
	q.matrixOutBus = ();
	q.matrixOutBus.all     = Bus.audio(s, 8);
	q.matrixOutBus.efx     = q.matrixOutBus.all.subBus(0, 2);
	q.matrixOutBus.thomas  = q.matrixOutBus.all.subBus(2, 2);
	q.matrixOutBus.kathrin = q.matrixOutBus.all.subBus(4, 2);
	q.matrixOutBus.local   = q.matrixOutBus.all.subBus(6, 2);



	//////// Groups

	q.inGroup = q.inGroup ?? {Group(s, \addToHead)};
	q.efxGroup = q.efxGroup ?? {Group(q.inGroup, \addAfter)};
	q.efxSubGroups = q.efxSubGroups.isNil.if{
		8.collect{
			Group(q.efxGroup, \addToTail)
		}
	};

	q.matrixGroup = q.matrixGroup ?? {Group(q.efxGroup, \addAfter)};
	q.outGroup = q.outGroup ?? {Group(q.matrixGroup, \addAfter)};

	s.sync;


	q.mappers = q.mappers ? ();

	/////////////// mapping from HW inputs resp. OSC sonification

	// q.mappers.efxFB = q.mappers.efxFB ?? {Synth(\map2_fb, [\from, q.matrixOutBus.efx.index, \to, q.efxBus.efx.index], q.inGroup)};
	// q.mappers.localIn = q.mappers.localIn ?? {Synth(\map2_dsm, [\from, q.hwLocalInBus.index, \to, q.efxBus.local.index], q.mappers.efxFB, \addAfter)};

	q.mappers.thomasIn = q.mappers.thomasIn ?? {
		Synth(\map2, [
			\from, q.hwThomasInBus.index,
			\to, q.efxBus.thomas.index
		// ], q.mappers.efxFB, \addAfter)
		], q.inGroup)
	};

	q.mappers.kathrinIn = q.mappers.kathrinIn ?? {
		Synth(\sonify2_4, [
			\to, q.efxBus.kathrin.index,
			\seed, 1048
		], q.inGroup)
	};

	q.mappers.localIn = q.mappers.localIn ?? {
		Synth(\sonify4_4, [
			\to, q.efxBus.local.index,
			\seed, 1048
		], q.inGroup)
	};


	/////////////// mapping from matrix output to HW-outputs

	q.mappers.spatialMixer = q.mappers.spatialMixer ?? {
		Synth(\map8to4_spatialLp, [
			\from, q.matrixOutBus.all,
			\to, q.hwLocalOutBus
		], q.outGroup)
	};

	q.mappers.thomasOut = q.mappers.thomasOut ?? {Synth(\map2, [\from, q.matrixOutBus.thomas.index, \to, q.hwThomasOutBus.index], q.outGroup)};
}
)


////////////////////////////////////////////////  control /////////////////////////

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
				q.matrix[c][r] = Synth(\map1_xfade, [\from, q.efxBus.all.index + c, \to, q.matrixOutBus.all.index + r, \fadeTime, q.mapFadeTime], q.matrixGroup);
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
				var in1 = q.efxBus.all.index + c;
				var in2 = c.even.if({in1+1}, {in1-1}); // always pairs

				[q.synthNames[r], [\in1, in1 - q.efxBus.all.index, \in2, in2- q.efxBus.all.index]].postln;

				q.efxChains[c][r] = Synth(q.synthNames[r], [\in1, in1, \in2, in2, \fadeTime, q.efxFadeTime], target, \addToHead);
				// q.monome.levset(c, r, q.efxHiVal)
				q.updateEfxKey(c, r, true);
			});
		});
	});

}, "/monome/grid/key");
);
)

/////////////////////////////////////////////////////////

q.mappers.kathrinIn

q.mappers.localIn.setn(\params, [0.1, 0.4, 0.8, 0.9])

q.mappers.localIn.set(\seed, 1234.rand)

q.mappers.kathrinIn.setn(\params, {1.0}!4);
q.mappers.localIn.setn(\params, {1.0}!4);

q.efxBus.all.scope

q.matrixOutBus.all.scope
q.hwLocalOutBus.scope
Synth





// x = Synth(\inTest, target: q.inGroup, addAction: \addToTail);
// x.free


q.matrixOutBus.all.scope

q.efxBus.all.scope


s.scope

(
OSCdef(\listener, {|msg|
    var data = msg[3..];
    data.postln;
	// ~testNetAddr.sendMsg("data", data);
}, '/analysis');
)