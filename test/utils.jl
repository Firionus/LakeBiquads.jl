using PyPlot
frequencies = range(16, 20000, length=10000)
fs = 96e3
function show_grid()
	minorticks_on()
	grid(which="major", color="gray", linestyle="-")
	grid(which="minor", color="lightgray", linestyle="--")
	xlabel("f in Hz")
end

function magplot(myfilter, frequencies=frequencies)
	plot(frequencies, 20*log10.(abs.(freqz(myfilter, frequencies, fs))), label="Level/dB")
	semilogx()
	show_grid()
end

function phaseplot(myfilter, frequencies=frequencies)
	plot(frequencies, angle.(freqz(myfilter, frequencies, fs)), label="Phase/rad")
	semilogx()
	show_grid()
end

function gdplot(myfilter, frequencies=frequencies)
	deltaf = frequencies.step.hi
	gdfrequencies = range(frequencies[1]+deltaf/2, frequencies[end]-deltaf/2, length=frequencies.len-1)
	phaseresponse = angle.(freqz(myfilter, frequencies, fs))|>unwrap
	gd = -diff(phaseresponse)/deltaf
	plot(gdfrequencies, gd)
	semilogx()
	show_grid()
end

function csvGDplot(filename)
	input = readdlm(filename, ';', skipstart=1)
	deltaf = [input[i+1,1]-input[i,1] for i=1:size(input,1)-1]
	gd = -diff(unwrap(input[:,3]/180*pi))./deltaf
	fAxis = [(input[i+1,1]+input[i,1])/2 for i=1:size(input,1)-1]
	plot(fAxis, gd)
	semilogx()
	show_grid()
end

"""
testplot(filename, myfilter)

plot csv (sep ';', skipstart=1, f/Hz, Level/dB, Phase/deg) level and phase
also calls magplot and phaseplot on given filter
"""
function testplot(filename, myfilter)
	input = readdlm(filename, ';', skipstart=1)
	plot(input[:,1], input[:,2], label="ref Level/dB")
	plot(input[:,1], input[:,3]/180*pi, label="ref Phase/rad")
	magplot(myfilter, input[:,1])
	phaseplot(myfilter, input[:,1])
	legend()
end
