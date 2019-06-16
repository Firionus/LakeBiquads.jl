# LakeBiquads.jl

Convert Lake Equalizer parameters to 96 kHz Biquads

All biquadratic EQ algorithms of Lake Controller, this does not include
Raised Cosine- or Mesa-Filters, were reverse engineered to closely or perfectly
mimic the original complex frequency response.

This potentially enables automatic optimization of Lake EQ parameters to
create a given target response or may help when you are interested in the
resulting frequency response of certain Lake filters.

The algorithms were only partly validated. No guarantees
in terms of accuracy are given. Especially additional delay when stacking
multiple parametrics may be a factor that is not modelled here.

## Installation

Install Julia. Run

```
]add LakeBiquads
```

and hit Backspace to exit Pkg mode.

To start using the package after installation, type

```
using LakeBiquads
```

## Batch Conversion



## Single Filters
