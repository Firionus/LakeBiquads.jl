"""
	HighPass(type::Symbol, f, dBperOct)

Return 96 kHz Biquad as DSP.SecondOrderSections that resembles the Highpass
functions of the Lake EQ.

`type` must be one of [:BT, :BS, :LR] resembling Butterworth, Bessel and
Linkwitz-Riley respectively. `dBperOct` must be one of [6, 12, 18, 24, 30, 36, 42, 48].

# Implementation

The design for the **Butterworth** filters uses the implementation by DSP.jl.

The **Linkwitz-Riley** filter is constructed from two of these Butterworth stages
at the same frequency.

The **Bessel** filter is constructed from the Polynomial Representation given in:

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
function HighPass(type::Symbol, f, dBperOct)
	responsetype = Highpass(f, fs=fs)
	return PassFilter(responsetype, type, dBperOct)
end

"""
	LowPass(type::Symbol, f, dBperOct)

Return 96 kHz Biquad as DSP.SecondOrderSections that resembles the Lowpass
functions of the Lake EQ.

`type` must be one of [:BT, :BS, :LR] resembling Butterworth, Bessel and
Linkwitz-Riley respectively. `dBperOct` must be one of [6, 12, 18, 24, 30, 36, 42, 48].

# Implementation

The design for the **Butterworth** filters uses the implementation by DSP.jl.

The **Linkiwtz-Riley** filter is constructed from two of these Butterworth stages
at the same frequency.

The **Bessel** filter is constructed from the Polynomial Representation given in:

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
function LowPass(type::Symbol, f, dBperOct)
	responsetype = Lowpass(f, fs=fs)
	return PassFilter(responsetype, type, dBperOct)
end

"""
	Bessel(N::Int)

Return analog Bessel prototype as DSP.ZeroPoleGain that fits Lake EQ after transformation
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




	#=
	#roughly hits frequency normalisation of Lake, but still inversion while converting
	#to highpass results in peaky GroupDelay

	#the correction fucks with the inversion in conversion to HighPass
	#need to properly normalize the Bessel filter for conversion to HighPass to work properly I guess

	#construct function for NLsolve to find halfPhase point
	myfilterphase(w) = angle.(freqs(myfilter2,w)) #no unwrap -> not monotonic! -> can't really work...
	halfPhase = rem2pi(angle.(freqs(myfilter2, 0))-N*pi/4, RoundNearest)
	#println(halfPhase)
	#wTest = range(0, stop=10, length=10000)
	#plot(wTest, angle.(freqs(myfilter2, wTest)))
	function func!(phase, w)
		phase[1] = myfilterphase(w[1])-halfPhase
	end

	#need to guess start right to get into right branch
	if N<= 4
		start = 2.
	else
		start=5.
	end

	res = nlsolve(func!, [start], autodiff=:forward)
	wHalfPhase = res.zero[1]
	#println(wHalfPhase)
	correctionFactor = 1/wHalfPhase
	=#

	#=

	#sucks completely

	#another new frequency normalization: same asymptote as Butterworth prototype of same order
	btproto = Butterworth(N)
	wRef = 1e8
	refMagnitude = abs(freqs(btproto, wRef))

	myfilterMagnitude(w) = abs(freqs(myfilter2, w))
	function func!(magn, w)
		magn[1] = myfilterMagnitude(w[1])-refMagnitude
	end
	res = nlsolve(func!, [wRef], autodiff=:forward)
	wRefMagnitude = res.zero[1]

	correctionFactor = wRef/wRefMagnitude
	=#

	#=
	#new freq normalization that makes GroupDelay at w=1 equal to
	# GD_max * N/(N+1)
	myphase(w) = angle(freqs(myfilter2, w))
	using ForwardDiff
	myfilterGD(w) = -ForwardDiff.derivative(myphase, w)
	GD0 = myfilterGD(0.)
	println("order ", N)
	println(GD0)
	targetGD = GD0*N/(N+1)
	println(targetGD)
	function func!(gd, w)
		gd[1] = myfilterGD(w[1])-targetGD
	end
	res = nlsolve(func!, [2.5], autodiff=:forward)
	targetGDFrequency = res.zero[1]
	println(targetGDFrequency)


	correctionFactor = 1/targetGDFrequency

	correctionFactor *= .1
	=#

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
