"""
	Peak(f, dBGain, BWoct)

Return 96 kHz Biquad as DSP.SecondOrderSections that resembles Lake Peak EQ.

The algorithm is a modified version of the method first presented in:

Orfanidis, JAES 1997 Issue 6: "Digital Parametric Equalizer Design with Prescribed Nyquist-Frequency Gain"
http://www.aes.org/e-lib/browse.cfm?elib=7854

In contrast to the method presented in the paper, this function does not
define linear Δf based on Bandwidth but forces the level to be half of
dBGain at the lower Bandwidth-defining point, e. g. 1 octave down from f when
the Bandwidth is 2 octaves. The resulting Biquads correlated very well with
measured frequency responses from the Lake Controller.
"""
function Peak(f, dBGain, BWoct)
	G_0 = 1 #gain at f=0
	G = 10^(dBGain/20) #gain at peak
	G_b = 10^(dBGain/40) #gain that defines bandwidth
	f_b = f * 2^(-BWoct/2) #lower frequency that defines bandwidth
	#calculate digital frequencies
	omega_0 = f/fs*2pi
	omega_b = f_b/fs*2pi
	#prewarping
	Omega_0 = tan(omega_0/2)
	Omega_b = tan(omega_b/2)
	#Nyquist-Gain from analog model
	#F is frequency in rad
	F_s = fs*pi #Nyquist frequency
	F_0 = f*2pi #peak frequency
	F_1 = F_0*2^(-BWoct/2) #lower frequency that defines bandwidth
	F_2 = F_0*2^(+BWoct/2) #upper frequency that defines bandwidth
	DeltaF = F_2-F_1
	A_analog = sqrt((G_b^2-G_0^2)/(G^2-G_b^2))*DeltaF
	B_analog = G * A_analog
	G_1 = sqrt((G_0*(F_s^2-F_0^2)^2+B_analog^2*F_s^2)/((F_s^2-F_0^2)^2+A_analog^2*F_s^2))
	#analog parameters to be bilinearly transformed, imported from wxMaxima
	A = sqrt(-(((G_0^2-G^2)*G_b^2+(G^2-G_0^2)*G_1^2)*Omega_b^4+((2*G^2-2*G_0^2)*sqrt((G_1^2-G^2)/(G_0^2-G^2))*G_b^2+(2*G^2*G_0^2-2*G^4)*sqrt((G_1^2-G^2)/(G_0^2-G^2))+(2*G_0^2-2*G^2)*G_1^2-2*G^2*G_0^2+2*G^4)*Omega_0^2*Omega_b^2+((G_1^2-G^2)*G_b^2-G_0^2*G_1^2+G^2*G_0^2)*Omega_0^4)/((G_0^2-G^2)*G_b^2-G^2*G_0^2+G^4))/Omega_b
	B = sqrt(-(((G^2*G_0^2-G^4)*G_b^2+(G^4-G^2*G_0^2)*G_1^2)*Omega_b^4+(((2*G^2*G_0-2*G_0^3)*G_1*sqrt((G_1^2-G^2)/(G_0^2-G^2))+(2*G_0^2-2*G^2)*G_1^2-2*G^2*G_0^2+2*G^4)*G_b^2+(2*G^2*G_0^3-2*G^4*G_0)*G_1*sqrt((G_1^2-G^2)/(G_0^2-G^2)))*Omega_0^2*Omega_b^2+((G^2*G_1^2-G^4)*G_b^2-G^2*G_0^2*G_1^2+G^4*G_0^2)*Omega_0^4)/((G_0^2-G^2)*G_b^2-G^2*G_0^2+G^4))/Omega_b
	W2 = ((G_1^2-G^2)/(G_0^2-G^2))^(1/2)*Omega_0^2 #W2 = W^2
	#bilinear transform
	b = [
		(G_1+G_0*W2+B),
		-2*(G_1-G_0*W2),
		(G_1-B+G_0*W2)]./(1+W2+A)
	a = [
		1,
		-2*(1-W2)/(1+W2+A),
		(1+W2-A)/(1+W2+A)]
	PeakFilter = SecondOrderSections(Biquad(b[1], b[2], b[3], a[2], a[3]))
	return PeakFilter
end
