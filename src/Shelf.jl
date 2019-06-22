"""
	HighShelf(f, dBGain, BWoct, fs=96e3)

Return 96 kHz Biquad as DSP.SecondOrderSections that resembles Lake High Shelf EQ.

The implementation is according to:

https://shepazu.github.io/Audio-EQ-Cookbook/audio-eq-cookbook.html (12.6.2019)

where the analog Q formula is utilized instead of the prewarped version to
fit the output of the Lake processor.
"""
function HighShelf(f, dBGain, BWoct, fs=96e3)
	#intermediate variables
	A = 10^(dBGain/40)
	w0 = 2*pi*f/fs
	#alpha = sin(w0)*sinh(log(2)/2*BWoct*w0/sin(w0))
	alpha = sin(w0)*sinh(log(2)/2*BWoct)
	#coefficients
	b0 = A*((A+1)+(A-1)*cos(w0)+2*sqrt(A)*alpha)
	b1 = -2*A*((A-1)+(A+1)*cos(w0))
	b2 = A*((A+1)+(A-1)*cos(w0)-2*sqrt(A)*alpha)
	a0 = (A+1)-(A-1)*cos(w0)+2*sqrt(A)*alpha
	a1 = 2*((A-1)-(A+1)*cos(w0))
	a2 = (A+1)-(A-1)*cos(w0)-2*sqrt(A)*alpha
	#normalize
	result = [b0 b1 b2 a1 a2]./a0
	return SecondOrderSections(Biquad(result...))
end

"""
	LowShelf(f, dBGain, BWoct, fs=96e3)

Return 96 kHz Biquad as DSP.SecondOrderSections that resembles Lake Low Shelf EQ.

The implementation is according to:

https://shepazu.github.io/Audio-EQ-Cookbook/audio-eq-cookbook.html (12.6.2019)

where the analog Q formula is utilized instead of the prewarped version to
fit the output of the Lake processor.
"""
function LowShelf(f, dBGain, BWoct, fs=96e3)
	#intermediate variables
	A = 10^(dBGain/40)
	w0 = 2*pi*f/fs
	#alpha = sin(w0)*sinh(log(2)/2*BWoct*w0/sin(w0))
	alpha = sin(w0)*sinh(log(2)/2*BWoct)
	#coefficients
	b0 = A*((A+1)-(A-1)*cos(w0)+2*sqrt(A)*alpha)
	b1 = 2*A*((A-1)-(A+1)*cos(w0))
	b2 = A*((A+1)-(A-1)*cos(w0)-2*sqrt(A)*alpha)
	a0 = (A+1)+(A-1)*cos(w0)+2*sqrt(A)*alpha
	a1 = -2*((A-1)+(A+1)*cos(w0))
	a2 = (A+1)+(A-1)*cos(w0)-2*sqrt(A)*alpha
	#normalize
	result = [b0 b1 b2 a1 a2]./a0
	return SecondOrderSections(Biquad(result...))
end
