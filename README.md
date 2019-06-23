
<a id='LakeBiquads.jl-1'></a>

# LakeBiquads.jl


Convert [Lake](https://www.lakeprocessing.com) Equalizer parameters to Biquads


All biquadratic EQ algorithms of Lake Controller (not the Raised Cosine or Mesa-Filters!), were reverse engineered to closely or perfectly mimic the original complex frequency response.


This allows a deeper understanding of what Lake's filters actually do and opens up the possibility for automatic equalization towards a given target response.


96 kHz is the Biquad calculation frequency for all Lake DSPs I am aware of and default throughout the library. Since this library can serve as general factory for Audio EQs, the sampling frequency for the single filters can be adjusted to your needs. Due to the symmetry at the Nyquist frequency sampling rate has a strong effect on the shape of the Biquad filters, especially at high frequencies and bandwidths. This means that filters at different sampling rates will not have the same transfer characteristic as Lake EQs at 96kHz.


In order to work with filter constructs, the package depends heavily on DSP.jl and may currently be affected by problems like https://github.com/JuliaDSP/DSP.jl/pull/284.


**Validation**


All tested EQs are automatically validated against measured curves of a PLM 20K44 in the unit tests with an accuracy of +- 0.5 deg in phase and +- 0.07 dB in level throughout the relevant passband. Not all available filter functions were measured and the range of tested filter parameters is small. I can give no guarantee on how accurately the Biquads represent original Lake EQs. For example additional delay when stacking multiple parametrics is not modelled here.


For details of the validation refer to the unit tests in the test folder.


<a id='Installation-1'></a>

## Installation


Install [Julia](https://julialang.org/downloads/).


Run


```julia
]add https://github.com/Firionus/LakeBiquads.jl
```


and hit Backspace once the installation is done to exit Pkg mode.


To start using the package after installation, type


```julia
using LakeBiquads
```


<a id='Batch-Conversion-1'></a>

## Batch Conversion

<a id='LakeBiquads.EQBiquads' href='#LakeBiquads.EQBiquads'>#</a>
**`LakeBiquads.EQBiquads`** &mdash; *Function*.



```julia
EQBiquads(filename)
```

Parse the given EQ file as Lake EQs and create a new file "nameBiquads.format" with 96kHz Biquads in space seperated format.

The EQ file allows specification of the Allpass, Peak, Highshelf, Lowshelf, Lowpass and Highpass Filters in the following format:

```
AP f order BWoct
P f dBGain BWoct
HS f dBGain BWoct
LS f dBGain BWoct
[LP/HP][BT/BS/LR][6/12/18/24/30/36/42/48] f
```

**Example**

```
EQBiquads("myEQ.txt")
```

would create a new file named "myEQBiquads.txt" containing Biquads.

**EQ File Examples**

```
LPBT30 1000  #Butterworth Lowpass with 30 dB/oct fall-off at 1000 Hz
P 1k 10 1    #Peak at 1 kHz with 10 dB Gain and a Bandwidth of 1 octave
AP 3e3 1 2   #Allpass at 3 kHz of order 1 with a Bandwidth of 2 octaves (order may only be 1 or 2)
```


<a target='_blank' href='https://github.com/Firionus/LakeBiquads.jl/blob/02a27212ea551749d85c8ef04a79e190a1c16bfd/src/LakeBiquads.jl#L37-L69' class='documenter-source'>source</a><br>


<a id='Single-Filters-1'></a>

## Single Filters


All Filter functions take the same arguments as the Lake EQ and return the filter as `SecondOrderSections`, as defined by the package DSP.jl.

<a id='LakeBiquads.Peak' href='#LakeBiquads.Peak'>#</a>
**`LakeBiquads.Peak`** &mdash; *Function*.



```julia
Peak(f, dBGain, BWoct, fs=96e3)
```

Return Biquad of sampling frequency fs as DSP.SecondOrderSections that resembles Lake Peak EQ.

The algorithm is a modified version of the method first presented in:

Orfanidis, JAES 1997 Issue 6: "Digital Parametric Equalizer Design with Prescribed Nyquist-Frequency Gain" http://www.aes.org/e-lib/browse.cfm?elib=7854

In contrast to the method presented in the paper, this function does not define linear Δf based on Bandwidth but forces the level to be half of dBGain at the lower Bandwidth-defining point, e. g. 1 octave down from f when the Bandwidth is 2 octaves. The resulting Biquads correlated very well with measured frequency responses from the Lake Controller.


<a target='_blank' href='https://github.com/Firionus/LakeBiquads.jl/blob/02a27212ea551749d85c8ef04a79e190a1c16bfd/src/Peak.jl#L1-L16' class='documenter-source'>source</a><br>

<a id='LakeBiquads.HighShelf' href='#LakeBiquads.HighShelf'>#</a>
**`LakeBiquads.HighShelf`** &mdash; *Function*.



```julia
HighShelf(f, dBGain, BWoct, fs=96e3)
```

Return Biquad of sampling frequency fs as DSP.SecondOrderSections that resembles Lake High Shelf EQ.

The implementation is according to:

https://shepazu.github.io/Audio-EQ-Cookbook/audio-eq-cookbook.html (12.6.2019)

where the analog Q formula is utilized instead of the prewarped version to fit the output of the Lake processor.


<a target='_blank' href='https://github.com/Firionus/LakeBiquads.jl/blob/02a27212ea551749d85c8ef04a79e190a1c16bfd/src/Shelf.jl#L1-L12' class='documenter-source'>source</a><br>

<a id='LakeBiquads.LowShelf' href='#LakeBiquads.LowShelf'>#</a>
**`LakeBiquads.LowShelf`** &mdash; *Function*.



```julia
LowShelf(f, dBGain, BWoct, fs=96e3)
```

Return Biquad of sampling frequency fs as DSP.SecondOrderSections that resembles Lake Low Shelf EQ.

The implementation is according to:

https://shepazu.github.io/Audio-EQ-Cookbook/audio-eq-cookbook.html (12.6.2019)

where the analog Q formula is utilized instead of the prewarped version to fit the output of the Lake processor.


<a target='_blank' href='https://github.com/Firionus/LakeBiquads.jl/blob/02a27212ea551749d85c8ef04a79e190a1c16bfd/src/Shelf.jl#L31-L42' class='documenter-source'>source</a><br>

<a id='LakeBiquads.LowPass' href='#LakeBiquads.LowPass'>#</a>
**`LakeBiquads.LowPass`** &mdash; *Function*.



```julia
LowPass(type::Symbol, f, dBperOct, fs=96e3)
```

Return Biquad of sampling frequency fs as DSP.SecondOrderSections that resembles the Lowpass functions of the Lake EQ.

`type` must be one of [:BT, :BS, :LR] resembling Butterworth, Bessel and Linkwitz-Riley respectively. `dBperOct` must be one of [6, 12, 18, 24, 30, 36, 42, 48].

**Implementation**

**Butterworth**

The design for the Butterworth filters uses the implementation by DSP.jl.

**Linkwitz-Riley**

The Linkwitz-Riley filters are constructed from two Butterworth stages at the same frequency.

**Bessel**

The Bessel filters are constructed from the Polynomial Representation given in:

https://onlinelibrary.wiley.com/doi/pdf/10.1002/9781119011866.app1 (12.6.2019)

(Appendix 1 of *Richard W. Middlestead*: Digital Communications with Emphasis on Data Modems: Theory, Analysis, Design, Simulation, Testing, and Applications. 1st edition, Published 2017 by John Wiley & Sons, Inc.)

The resulting filter is normalized to be -3 dB at 1 rad/s. The -3 dB frequencies for all orders of Bessel filters in the Lake processor at a frequency of 1 kHz were measured and are used to shift the Bessel prototype to fit the Lake filter after adjustment to the given frequency and filter type.

Note that for odd orders of Bessel filters, the polarity is reversed.


<a target='_blank' href='https://github.com/Firionus/LakeBiquads.jl/blob/02a27212ea551749d85c8ef04a79e190a1c16bfd/src/LowHighPass.jl#L58-L94' class='documenter-source'>source</a><br>

<a id='LakeBiquads.HighPass' href='#LakeBiquads.HighPass'>#</a>
**`LakeBiquads.HighPass`** &mdash; *Function*.



```julia
HighPass(type::Symbol, f, dBperOct, fs=96e3)
```

Return Biquad of sampling frequency fs as DSP.SecondOrderSections that resembles the Highpass functions of the Lake EQ.

`type` must be one of [:BT, :BS, :LR] resembling Butterworth, Bessel and Linkwitz-Riley respectively. `dBperOct` must be one of [6, 12, 18, 24, 30, 36, 42, 48].

**Implementation**

**Butterworth**

The design for the Butterworth filters uses the implementation by DSP.jl.

**Linkwitz-Riley**

The Linkwitz-Riley filters are constructed from two Butterworth stages at the same frequency.

**Bessel**

The Bessel filters are constructed from the Polynomial Representation given in:

https://onlinelibrary.wiley.com/doi/pdf/10.1002/9781119011866.app1 (12.6.2019)

(Appendix 1 of *Richard W. Middlestead*: Digital Communications with Emphasis on Data Modems: Theory, Analysis, Design, Simulation, Testing, and Applications. 1st edition, Published 2017 by John Wiley & Sons, Inc.)

The resulting filter is normalized to be -3 dB at 1 rad/s. The -3 dB frequencies for all orders of Bessel filters in the Lake processor at a frequency of 1 kHz were measured and are used to shift the Bessel prototype to fit the Lake filter after adjustment to the given frequency and filter type.

The transformation from lowpass prototype to highpass is then achieved by simply adding n zeros to the filter at 0+0im where n is the filter order.

This is contrary to the standard method of converting a lowpass to highpass where the substitution s -> 1/s is performed. However, while this transformation does accurately mirror the Level response, the group delay of the newly created highpass is not flat anymore but peaked above orders of 2. This peak gets stronger the higher the order of the filter.

Lake provides flat group delay response in Bessel highpass filters by adding zeros in the nominator, but not reversing the coefficient order in the denominator, both of which would happen in the substitution s -> 1/s. The Lake version is still approximately equal to the subtitution method because Bessel polynomials are approximately reversible with the right normalization for s. (see https://www.rane.com/note147.html (22.6.2019))

Note that in contrast to the Lake Bessel lowpass filters, odd orders are not phase-inverted.


<a target='_blank' href='https://github.com/Firionus/LakeBiquads.jl/blob/02a27212ea551749d85c8ef04a79e190a1c16bfd/src/LowHighPass.jl#L1-L52' class='documenter-source'>source</a><br>

<a id='LakeBiquads.AllPass' href='#LakeBiquads.AllPass'>#</a>
**`LakeBiquads.AllPass`** &mdash; *Function*.



```julia
AllPass(f, order, BWoct, fs=96e3)
```

Return Biquad of sampling frequency fs as DSP.SecondOrderSections that resembles Lake 1st- or 2nd-order Allpass.

**Implementation**

The 2nd order Allpass ist constructed according to

https://shepazu.github.io/Audio-EQ-Cookbook/audio-eq-cookbook.html (12.6.2019)

where the analog Q formula is utilized instead of the prewarped version to fit the output of the Lake processor. The Bandwidth of the Lake processor for some dubious reason is double that of the method proposed in the link, so a factor 2 was added to account for this.

The 1st order Allpass is constructed from the simple zero position at 1 and pole position at -1 and a polarity reversal, which already results in an analog 1st order Allpass prototype centered around 1 rad/s that can be used with the DSP.Lowpass responsetype (only shifts frequency) to design the Biquad.


<a target='_blank' href='https://github.com/Firionus/LakeBiquads.jl/blob/02a27212ea551749d85c8ef04a79e190a1c16bfd/src/Allpass.jl#L1-L22' class='documenter-source'>source</a><br>


<a id='Utilities-1'></a>

## Utilities

<a id='LakeBiquads.BiquadArray' href='#LakeBiquads.BiquadArray'>#</a>
**`LakeBiquads.BiquadArray`** &mdash; *Function*.



```julia
BiquadArray(x::SecondOrderSections)
```

Construct 2D Array of Biquad Parameters from `x`.

The returned Array for 2 Biquads is of the structure:

```
2×5 Array{Float64,2}:
 b0  b1  b2  a1  a2
 b0  b1  b2  a1  a2
```

Note that the Gain of the SecondOrderSections is spread evenly over all Biquads.


<a target='_blank' href='https://github.com/Firionus/LakeBiquads.jl/blob/02a27212ea551749d85c8ef04a79e190a1c16bfd/src/LakeBiquads.jl#L12-L25' class='documenter-source'>source</a><br>

<a id='LakeBiquads.Bessel' href='#LakeBiquads.Bessel'>#</a>
**`LakeBiquads.Bessel`** &mdash; *Function*.



```julia
Bessel(N::Int)
```

Return analog Bessel lowpass prototype as DSP.ZeroPoleGain that fits Lake EQ after transformation.


<a target='_blank' href='https://github.com/Firionus/LakeBiquads.jl/blob/02a27212ea551749d85c8ef04a79e190a1c16bfd/src/LowHighPass.jl#L100-L105' class='documenter-source'>source</a><br>


<a id='Filter-conversion-1'></a>

### Filter conversion


Conversion between different filter representations, such as SecondOrderSections and ZeroPoleGain, can be achieved with the utilities provided by [DSP.jl](https://github.com/JuliaDSP/DSP.jl).


To see Poles and Zeros for a given filter, you could for example run:


```julia
using DSP
myfilter = Bessel(3)
ZeroPoleGain(myfilter)
```

