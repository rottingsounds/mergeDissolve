


Ndef(\sine, {
	var src = DSMSine.ar(\freq.kr(100));

	LPF.ar(src, s.sampleRate/4)!2
}).edit



Server.killAll|

(
s.options.sampleRate_(192000);

s.reboot;
s.waitForBoot{
	b = Buffer.readChannel(s, "/Users/tboverma/Library/Application Support/SuperCollider/downloaded-quarks/Dirt-Samples/breaks152/000_AMEN.WAV", channels: 0);
}
)

(
Ndef(\dsmTest).addSpec(\wet, [0, 2, \lin, 1, 0]);
Ndef(\dsmTest).addSpec(\fb, [0, 2]);
Ndef(\dsmTest).addSpec(\amp, [0, 1]);
Ndef(\dsmTest).addSpec(\rate, [0.1, 2]);
Ndef(\dsmTest).addSpec(\lpFreq, [100, s.sampleRate/2, \exp, 1]);

Ndef(\dsmTest, {
	// var src = SinOscFB.ar(\freq.kr(100), \fb.kr(0), \amp.kr(0.1));
	var lpFreq = \lpFreq.kr(1000);

	var src = PlayBuf.ar(1, b, BufRateScale.kr(b) * \rate.kr(1), loop:1) * \amp.kr(0.1);
	var dsm = DSM2.ar(src, polarity: \bipolar);
	Select.ar(\wet.kr(0), [src, dsm, DSM2PCM.ar(dsm, lpFreq)])!2;
})
)


Ndef(\dsmTest).edit