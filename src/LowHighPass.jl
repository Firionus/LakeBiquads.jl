"""
	HighPass(type::Symbol, f, dBperOct, fs=96e3)

Return 96 kHz Biquad as DSP.SecondOrderSections that resembles the Highpass
functions of the Lake EQ.

`type` must be one of [:BT, :BS, :LR] resembling Butterworth, Bessel and
Linkwitz-Riley respectively. `dBperOct` must be one of [6, 12, 18, 24, 30, 36, 42, 48].

# Implementation

## Butterworth

The design for the Butterworth filters uses the implementation by DSP.jl.

## Linkwitz-Riley

The Linkwitz-Riley filters are constructed from two Butterworth stages
at the same frequency.

## Bessel

The Bessel filters are constructed from the Polynomial Representation given in:

https://onlinelibrary.wiley.com/doi/pdf/10.1002/9781119011866.app1 (12.6.2019)

Digital Communications with Emphasis on Data Modems: Theory, Analysis, Design, Simulation, Testing, and Applications,

First Edition. Richard W. Middlestead.

© 2017 John Wiley & Sons, Inc. Published 2017 by John Wiley & Sons, Inc.

The resulting filter is normalized to be -3 dB at 1 rad/s. The -3 dB frequencies
for all orders of Bessel filters in the Lake processor at a frequency of 1 kHz
were measured and are used to shift the Bessel prototype to fit the Lake
filter after adjustment to the given frequency and filter type.

The transformation from lowpass prototype to highpass is then achieved by simply adding
n zeros to the filter at 0+0im where n is the filter order.

This is contrary to the standard method of converting a lowpass to
highpass where the substitution s -> 1/s is performed. However, while
this transformation does accurately mirror the Level response, the group delay
of the newly created highpass is not flat anymore but peaked above orders of 2.
This peak gets stronger the higher the order of the filter.

Lake provides flat group delay response in Bessel highpass filters by adding zeros
in the nominator, but not reversing the coefficient order in the denominator, both
of which would happen in the substitution s -> 1/s. The Lake version is still
approximately equal to the subtitution method because Bessel polynomials are approximately
reversible with the right normalization for s. (see https://www.rane.com/note147.html (22.6.2019))

Note that in contrast to the Lake Bessel lowpass filters, odd orders are not phase-inverted.
"""
function HighPass(type::Symbol, f, dBperOct, fs=96e3)
	responsetype = Highpass(f, fs=fs)
	return PassFilter(responsetype, type, dBperOct)
end

"""
	LowPass(type::Symbol, f, dBperOct, fs=96e3)

Return 96 kHz Biquad as DSP.SecondOrderSections that resembles the Lowpass
functions of the Lake EQ.

`type` must be one of [:BT, :BS, :LR] resembling Butterworth, Bessel and
Linkwitz-Riley respectively. `dBperOct` must be one of [6, 12, 18, 24, 30, 36, 42, 48].

# Implementation

## Butterworth

The design for the Butterworth filters uses the implementation by DSP.jl.

## Linkwitz-Riley

The Linkwitz-Riley filters are constructed from two Butterworth stages
at the same frequency.

## Bessel

The Bessel filters are constructed from the Polynomial Representation given in:

https://onlinelibrary.wiley.com/doi/pdf/10.1002/9781119011866.app1 (12.6.2019)

Digital Communications with Emphasis on Data Modems: Theory, Analysis, Design, Simulation, Testing, and Applications,

First Edition. Richard W. Middlestead.

© 2017 John Wiley & Sons, Inc. Published 2017 by John Wiley & Sons, Inc.

The resulting filter is normalized to be -3 dB at 1 rad/s. The -3 dB frequencies
for all orders of Bessel filters in the Lake processor at a frequency of 1 kHz
were measured and are used to shift the Bessel prototype to fit the Lake
filter after adjustment to the given frequency and filter type.

Note that for odd orders of Bessel filters, the polarity is reversed.
"""
function LowPass(type::Symbol, f, dBperOct, fs=96e3)
	responsetype = Lowpass(f, fs=fs)
	return PassFilter(responsetype, type, dBperOct)
end

"""
	Bessel(N::Int)

Return analog Bessel lowpass prototype as DSP.ZeroPoleGain that fits Lake EQ
after transformation.
"""
function Bessel(N::Int)
	b(n::Int) = factorial(2*N-n)//(2^(N-n)*factorial(N-n)*factorial(n))
	denominator = [b(n)|>Float64 for n=N:-1:0]
	nominator = zeros(N+1)
	nominator[end] = denominator[end]

	if isodd(N)
		nominator = -nominator
	end

	myfilter = PolynomialRatio(nominator, denominator)
	myfilter2 = convert(ZeroPoleGain, myfilter)

	#construct function for NLsolve to find -3dB point
	myfilterdB(w) = 20*log10.(abs.(freqs(myfilter2, w)))
	function func!(dB, w)
	   dB[1] = myfilterdB(w[1]).+3
	end

	res = nlsolve(func!, [3.], autodiff=:forward)
	w3dB = res.zero[1]

	BesselCorrectionFactor = 1/w3dB

	LakeCorrectionFactor = ([997.2, 784.8, 710.4, 659.2, 615.2, 577.5, 544.6, 516.7]./1000)[N]

	correctionFactor = LakeCorrectionFactor*BesselCorrectionFactor

	myfilter3 = ZeroPoleGain(myfilter2.z .* correctionFactor,
							 myfilter2.p .* correctionFactor,
				myfilter2.k * correctionFactor^(length(myfilter2.p)-length(myfilter2.z)))
	return myfilter3
end

function BesselInvert(prototype)
	N = length(prototype.p)
	if isodd(N)
		newGain = -prototype.k
	else
		newGain = prototype.k
	end
	return ZeroPoleGain(fill(0+0im, N), prototype.p, newGain)
end

function PassFilter(responsetype, type, dBperOct)
	if dBperOct in [6,12,18,24,30,36,42,48]
		Poles = dBperOct/6|>Int
	else
		error("dBperOct is not one of [6,12,18,24,30,36,42,48]")
	end

	if type == :BT
		designmethod = Butterworth(Poles)
		Filter = convert(SecondOrderSections, digitalfilter(responsetype, designmethod))
	elseif type == :BS
		designmethod = Bessel(Poles)
		if typeof(responsetype)<:Lowpass
			Filter = convert(SecondOrderSections, digitalfilter(responsetype, designmethod))
		else #Highpass
			hp_responsetype = Lowpass(responsetype.w)
			hpbs_designmethod = BesselInvert(designmethod)
			Filter = convert(SecondOrderSections, digitalfilter(hp_responsetype, hpbs_designmethod))
		end
	elseif type == :LR
		if Poles in [2,4,6,8]
			designmethod = Butterworth(Poles/2|>Int)
			OneStage = convert(ZeroPoleGain, digitalfilter(responsetype, designmethod))
			TwoStages = OneStage*OneStage
			Filter = SecondOrderSections(TwoStages)
		else
			error("Linkwitz-Riley must have dBperOct of 12, 24, 36 or 48")
		end
	else
		error("unknown Low- or Highpass type")
	end
	return Filter
end
