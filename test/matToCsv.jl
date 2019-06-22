"""
read all WinMF *.mat files in current folder and convert them to log scaled csv
frequency responses
"""
using MAT, Dierckx, DelimitedFiles, myutils

function logResample(data1::Vector, samplerate::Number, fLog=logrange(10, 23e3, points_per_octave=96))
	nData = length(data1)
	fData = range(0, stop=samplerate/2, length=nData)
	a=3
	n=((fLog[end]-fLog[end-1])/(fData[2]-fData[1])*2*a) |>round|>Int
	x = range(-1, stop=1, length=n)
	lanczos = sinc.(x).*sinc.(x*a)
	lanczos ./= sum(lanczos)
	function lanczosInterpolate(f0, d, itp)
		fAxis = range(f0-a*d, stop=f0+a*d, length=n)
		pointValues = itp(fAxis)
		return sum(lanczos .* pointValues)
	end

	logData = Array{Complex{Float64}, 1}(undef, length(fLog))

	itpReal = Spline1D(fData, real.(data1))
	itpImag = Spline1D(fData, imag.(data1))

	for i in 1:length(fLog)
		f0 = fLog[i]
		if i<length(fLog)
			d = fLog[i+1]-f0
		else
			d = -fLog[i-1]+f0
		end
		logData[i] = lanczosInterpolate(f0, d, itpReal) + im*lanczosInterpolate(f0, d, itpImag)
	end

	arr = Float32[fLog 20*log10.(abs.(logData)) angle.(logData)/pi*180]

	return arr
end

function myCSVwrite(arr, filename)
	file = open(filename, "w")
	write(file, "f in Hz; Level in dB; Phase in deg\n")
	writedlm(file, arr, ';')
	close(file)
end


inNames = filter(x -> splitext(x)[2]==".mat", readdir())
for i=1:length(inNames)
	name = inNames[i]
	vars = matread(name)
	myCSVwrite(logResample(vars["data"]|>vec, vars["samplerate"]), string(name[10:end-3], "csv"))
end
