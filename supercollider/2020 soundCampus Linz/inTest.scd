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
// 	// Out.ar(q.efxBus.all, Silent.ar + ({|i|i+1}!8 / 10))
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
Ndef(\inTest).play(q.efxBus.all, 8, q.inGroup)
Ndef(\inTest).stop
Ndef(\inTest).scope
Ndef(\inTest).play
