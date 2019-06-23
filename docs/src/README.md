# LakeBiquads.jl

Convert [Lake](https://www.lakeprocessing.com) Equalizer parameters to Biquads

All biquadratic EQ algorithms of Lake Controller (not the Raised Cosine or Mesa-Filters!),
were reverse engineered to closely or perfectly
mimic the original complex frequency response.

This allows a deeper understanding of what Lake's filters actually do and opens up
the possibility for automatic equalization towards a given target response.

96 kHz is the Biquad calculation frequency for all Lake DSPs I am aware of and default
throughout the library. Since this library can serve as general factory for Audio EQs, the
sampling frequency for the single filters can be adjusted to your needs.
Due to the symmetry at the Nyquist frequency sampling rate has a strong effect on
the shape of the Biquad filters, especially at high frequencies and bandwidths.
This means that filters at different sampling rates will not have the same
transfer characteristic as Lake EQs at 96kHz.

In order to work with filter constructs, the package depends heavily on
DSP.jl and may currently be affected by problems like https://github.com/JuliaDSP/DSP.jl/pull/284.

**Validation**

All tested EQs are automatically validated against measured curves of a PLM 20K44
in the unit tests with an accuracy of +- 0.5 deg in phase and +- 0.07 dB in level throughout
the relevant passband.
Not all available filter functions were measured and the range of tested filter
parameters is small. I can give no guarantee on how accurately the Biquads represent
original Lake EQs. For example additional delay when stacking multiple parametrics is not modelled here.

For details of the validation refer to the unit tests in the test folder.

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

## Batch Conversion

```@docs
EQBiquads
```

## Single Filters

All Filter functions take the same arguments as the Lake EQ and return the
filter as `SecondOrderSections`, as defined by the package DSP.jl.

```@docs
Peak
HighShelf
LowShelf
LowPass
HighPass
AllPass
```

## Utilities

```@docs
BiquadArray
Bessel
```

### Filter conversion

Conversion between different filter representations, such as SecondOrderSections and ZeroPoleGain,
can be achieved with the utilities provided by [DSP.jl](https://github.com/JuliaDSP/DSP.jl).

To see Poles and Zeros for a given filter, you could for example run:

```julia
using DSP
myfilter = Bessel(3)
ZeroPoleGain(myfilter)
```
