using LakeBiquads, DelimitedFiles, DSP, Test
fs=96e3

#enable for testplot
#requires PyPlot
#include("utils.jl")

function compareReference(refName, testFilter; fStart = nothing, fStop=22e3, plot=false)
    plot && testplot(refName, testFilter)
    input = readdlm(refName, ';', skipstart=1)
    fIn = input[:,1]
    dBIn = input[:,2]
    phaseIn = input[:,3]
    if fStart==nothing
        fStart = minimum(fIn)
    end
    if fStop==nothing
        fStop = maximum(fIn)
    end
    for i in eachindex(fIn)
        if fIn[i] > fStop
            break
        elseif fIn[i] >= fStart
            #print(i, " ")
            if isapprox(dBIn[i], 20*log10(abs(freqz(testFilter, fIn[i], fs))), atol=.07) != true
                println(refName, ": failed level at frequency ", fIn[i], " Hz")
                return false
            end
            if isapprox(phaseIn[i], angle(freqz(testFilter, fIn[i], fs))/pi*180, atol=.5) != true
                println(refName, ": failed phase at frequency ", fIn[i], " Hz")
                return false
            end
        end
    end
    return true
end

@testset "all Tests" begin
    @testset "Reference comparisons" begin
        @test compareReference("AP 10k 1 3.csv", AllPass(10e3, 1, 3))
        @test compareReference("AP 10k 2 2.csv", AllPass(10e3, 2, 2))
        @test compareReference("P 10k 15 2.csv", Peak(10e3, 15, 2))
        @test compareReference("P 100 -6 1.csv", Peak(100, -6, 1))
        @test compareReference("LS 10k 15 2.5.csv", LowShelf(10e3, 15, 2.5))
        @test compareReference("HS 5k 10 2.csv", HighShelf(5e3, 10, 2))

        #LowHighPass tests, take care to adjust fStart/fStop individually to surpress Noise
        @test compareReference("LPBT24 10k.csv", LowPass(:BT, 10e3, 24), plot=false)
        @test compareReference("LPBT48 1k.csv", LowPass(:BT, 1e3, 48), fStop=2e3, plot=false)

        @test compareReference("LPBT6 10k HPLR12 100.csv", LowPass(:BT, 10e3, 6)*HighPass(:LR, 100, 12), fStart=30, plot=false) #divergence towards low frequencies

        @test compareReference("HPBT12 40.csv", HighPass(:BT, 40, 12), fStart=16, plot=false) #curves diverge towards low frequencies
        @test compareReference("HPLR48 1k.csv", HighPass(:LR, 1e3, 48), fStart=500, plot=false)

        #Lowpass Bessel
        @test compareReference("LPBS6 1k.csv", LowPass(:BS, 1e3, 6), plot=false)
        @test compareReference("LPBS12 1k.csv", LowPass(:BS, 1e3, 12), fStop=10e3, plot=false)
        @test compareReference("LPBS18 1k.csv", LowPass(:BS, 1e3, 18), fStop=6e3, plot=false)
        @test compareReference("LPBS24 1k.csv", LowPass(:BS, 1e3, 24), fStop=4e3, plot=false)
        @test compareReference("LPBS24 1k.csv", LowPass(:BS, 1e3, 24), fStop=4e3, plot=false)
        @test compareReference("LPBS30 1k.csv", LowPass(:BS, 1e3, 30), fStop=2.5e3, plot=false)
        @test compareReference("LPBS36 1k.csv", LowPass(:BS, 1e3, 36), fStop=2.5e3, plot=false)
        @test compareReference("LPBS42 1k.csv", LowPass(:BS, 1e3, 42), fStop=2e3, plot=false)
        @test compareReference("LPBS42 10k.csv", LowPass(:BS, 10e3, 42), fStop=18e3, plot=false)
        @test compareReference("LPBS48 1k.csv", LowPass(:BS, 1e3, 48), fStop=2e3, plot=false)

        #Highpass Bessel
        @test compareReference("HPBS6 1k.csv", HighPass(:BS, 1e3, 6), fStart=15, plot=false)
        @test compareReference("HPBS12 1k.csv", HighPass(:BS, 1e3, 12), fStart=150, plot=false)
        @test compareReference("HPBS18 1k.csv", HighPass(:BS, 1e3, 18), fStart=150, plot=false)
        @test compareReference("HPBS24 1k.csv", HighPass(:BS, 1e3, 24), fStart=300, plot=false)
        @test compareReference("HPBS30 1k.csv", HighPass(:BS, 1e3, 30), fStart=350, plot=false)
        @test compareReference("HPBS36 1k.csv", HighPass(:BS, 1e3, 36), fStart=400, plot=false)
        @test compareReference("HPBS48 1k.csv", HighPass(:BS, 1e3, 48), fStart=500, plot=false)
    end

    @testset "Batch conversion" begin
        EQBiquads("testEQFile.txt") #just check for errors on execution
        #TODO
        #read resulting file and compare to single calculated filters to check for
        #parse errors
    end

    #Peak with 0dB gain should give unity filter
    @test freqz(Peak(10e3, 0, 1), range(0, stop=π, length=250)) ≈ ones(250)
end
