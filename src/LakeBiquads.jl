module LakeBiquads

export EQBiquads, BiquadArray, AllPass, HighPass, LowPass, Peak, HighShelf, LowShelf, Bessel

using DelimitedFiles, DSP, NLsolve

include("Peak.jl")
include("Shelf.jl")
include("LowHighPass.jl")
include("Allpass.jl")

"""
	BiquadArray(x::SecondOrderSections)

Construct 2D Array of Biquad Parameters from `x`.

The returned Array for 2 Biquads is of the structure:
```
2×5 Array{Float64,2}:
 b0  b1  b2  a1  a2
 b0  b1  b2  a1  a2
```

Note that the Gain of the SecondOrderSections is spread evenly over all Biquads.
"""
function BiquadArray(x::SecondOrderSections)
	biquads = x.biquads
	n = length(biquads)
	gain = x.g^(1/n)
	out = zeros(n, 5)
	for i in 1:n
		out[i, :] = [gain*biquads[i].b0 gain*biquads[i].b1 gain*biquads[i].b2 biquads[i].a1 biquads[i].a2]
	end
	return out
end

"""
	EQBiquads(filename)

Parse the given EQ file as Lake EQs and create a new file "nameBiquads.format"
with 96kHz Biquads in space seperated format.

All biquadratic Lake EQs (not the Raised Cosine or Mesa-Filters) were
reverse engineered, so that 96 kHz Biquads can be calculated that closely or
maybe perfectly mimic the level and phase response of a Lake Controller
with the same EQ settings.

The EQ file allows specification of the Allpass, Peak, Highshelf, Lowshelf,
Lowpass and Highpass Filters in the following format:

```
AP f order BWoct
P f dBGain BWoct
HS f dBGain BWoct
LS f dBGain BWoct
[LP/HP][BT/BS/LR][6/12/18/24/30/36/42/48] f
```

# Example


	EQBiquads("myEQ.txt")


would create a new file named "myEQBiquads.txt" containing Biquads.

# EQ File Examples

```
LPBT30 1000  #Butterworth Lowpass with 30 dB/oct fall-off at 1000 Hz
P 1k 10 1    #Peak at 1 kHz with 10 dB Gain and a Bandwidth of 1 octave
AP 3e3 1 2   #Allpass at 3 kHz of order 1 with a Bandwidth of 2 octaves (order may only be 1 or 2)
```
"""
function EQBiquads(filename)
	EQs = readdlm(filename, ' ')
	n = size(EQs, 1)
	BiquadParams = Core.Array{Float64,2}(undef, 0,5)
	for i in 1:n
		#try
			EQtype = EQs[i,1]
			f = EQs[i,2]
			if f isa SubString
				f = replace(f, "k"=>".")
				f = f * "e3"
				f = parse(Float64, f)
			end
			if size(EQs,2)>=3
				dBGain = EQs[i,3]
				BWoct = EQs[i,4]
			end
			if EQtype == "P"
				BiquadParams = [BiquadParams; Peak(f, dBGain, BWoct)|>BiquadArray]
			elseif EQtype[1:2] in ["HP", "LP"]
				type = Symbol(EQtype[3:4])
				dBperOct = parse(Int64, EQtype[5:end])
				if EQtype[1:2] == "HP"
					bf = HighPass(type, f, dBperOct)
				else
					bf = LowPass(type, f, dBperOct)
				end
				BiquadParams = [BiquadParams; BiquadArray(bf)]
			elseif EQtype == "HS"
				BiquadParams = [BiquadParams; HighShelf(f, dBGain, BWoct)|>BiquadArray]
			elseif EQtype == "LS"
				BiquadParams = [BiquadParams; LowShelf(f, dBGain, BWoct)|>BiquadArray]
			elseif EQtype == "AP"
				BiquadParams = [BiquadParams; AllPass(f, dBGain, BWoct)|>BiquadArray] #dBGain is used here as specifying the order of the AllPass, because it controls the amount of added phase as Gain in a Peak EQ
			else
				error(string("Unknown Filter type. Execution stopped and no changes were written to filesystem. "))
			end
		# catch err
		# 	println(string("Error while parsing line ", i, ":"))
		# 	println(stacktrace())
		# 	throw(err)
		# end
	end
	#filename processing
	sep = split(filename, ".")
	newFilenamePrevious = join(sep[1:end-1], '.')
	newFilename = string(newFilenamePrevious, "Biquads.", sep[end])

	writedlm(newFilename, BiquadParams, ' ')
	#post processing to add DOS style line breaks
	str = read(newFilename, String)
	str = replace(str, "\n"=>"\r\n")
	write(newFilename, str)
end


end # module
