[1, 2, 4, 8].do{|i|

	[4, 10].do{|numParams|
		SynthDef("sonify%_%".format(i, numParams), {|to = 2, seed = 100|

			var params = \params.kr(0!numParams, 0.1);
			var freqs, amps, sndIdxs;
			var trig = Changed.kr(seed);
			var src;

			RandSeed.kr(trig, seed);

			freqs = params.collect{|p|
				TExpRand.kr(50, 1600, trig) * (1 + (0.03*p)); // almost static freqs
			};

			// fixme: scramble should be re-seedable
			amps = params.scramble.collect{|p|
				p * 0.9 + 0.1;
			};

			// fixme: scramble should be re-seedable
			sndIdxs = params.scramble.collect{|p|
				p * 3;
			};

			src = [freqs, amps, sndIdxs].flop.collect{|args, i|
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

			(i == 1).if({
				src = src.flat.sum;
			}, {
				(i != numParams).if({
					src = SplayAz.ar(i, src, orientation: 0);
				});
			});

			src = src.tanh;
			Out.ar(to, DSM2.ar(src, \bipolar))
		}).add;
	}
}