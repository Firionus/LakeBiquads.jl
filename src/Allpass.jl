"""
	AllPass(f, order, BWoct)

Return 96 kHz Biquad as DSP.SecondOrderSections that resembles Lake 1st- or
2nd-order Allpass.

# Implementation

The 2nd order Allpass ist constructed according to

https://shepazu.github.io/Audio-EQ-Cookbook/audio-eq-cookbook.html (12.6.2019)

where the analog Q formula is utilized instead of the prewarped version to
fit the output of the Lake processor. The Bandwidth of the Lake processor
for some dubious reason is double that of the method proposed in the link, so
a factor 2 was added to account for this.

The 1st order Allpass is constructed from the simple zero position at 1 and
pole position at -1 and a polarity reversal, which already results in an
analog 1st order Allpass prototype centered around 1 rad/s that can be used
with the DSP.Lowpass responsetype (only shifts frequency) to design the Biquad.
"""
function AllPass(f, order, BWoct)
	w0 = 2*pi*f/fs
	if order==2
		BWoct = 2*BWoct #somehow necessary in Lake
		alpha = sin(w0)*sinh(log(2)/2*BWoct)

		b0 = 1-alpha
		b1 = -2*cos(w0)
		b2 = 1+alpha
		a0 = 1+alpha
		a1 = -2*cos(w0)
		a2 = 1-alpha

		result = [b0 b1 b2 a1 a2]./a0
		Filter = SecondOrderSections(Biquad(result...))
	elseif order==1
		analogPrototype = ZeroPoleGain([1], [-1], -1)
		Filter = convert(SecondOrderSections, digitalfilter(Lowpass(f, fs=fs), analogPrototype))
	else
		error(string("Allpass order must be 1 or 2. Was given ", order))
	end
	return Filter
end
