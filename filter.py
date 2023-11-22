import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from fxpmath import Fxp

ORDER = 1024
T = 0.1
F_c = 2880
N = 100000

F_s = 8000  # Lowest sample rate supported by DAC
F_s_inv = 1 / F_s

FPGA_MULTIPLIER_NUM_BITS = 22

n = np.linspace(-F_s_inv * ORDER / 2, F_s_inv * ORDER / 2, ORDER)

print(n)

x = np.linspace(-T, T, N)
t = np.arange(N) / F_s
samples = np.arange(ORDER)
t_window = np.arange(ORDER) / F_s


def h_lavpass(t):
    return (1 / (20 * np.pi * t)) * np.sin(20 * np.pi * t)


def h_cos(t):
    return 2 * np.cos(2 * np.pi * F_c * t)


def h_bandpass(t):
    return h_lavpass(t) * h_cos(t)


fix, ax = plt.subplots(1, 1, squeeze=True)

ax.plot(x, h_bandpass(x), label="sinc($20\pi t$) $\cdot$ $2\cos(2\pi f_c t)$")
ax.stem(n, h_bandpass(n), "C1", label="sinc($20\pi n$) $\cdot$ $2\cos(2\pi f_c n)$")

ax.set_ylabel("Amplitude")
ax.set_xlabel("Tid (s)")

ax.set_xlim(-T, T)
ax.legend()


fig, ax = plt.subplots(3, 1, squeeze=True, tight_layout=True)

ax[0].set_title("Impulsrespons")
ax[0].set_xlabel("Tid (s)")
ax[0].plot(x, h_bandpass(x), label="$h_{Båndpass}(t)$")
ax[0].plot(x, h_lavpass(x), label="$h_{Lavpass}(t)$")

# Start by only finding the coeffisients for the low-pass filter.
coeff = h_lavpass(n)
np.nan_to_num(coeff, copy=False, nan=1)  # Remove NaN and replace with 1
# Find the total sum of the coefficient to see what the response is if a DC-signal is applied
sum_coeff = np.sum(coeff)
# Normalise so that the sum of all coefficients equal to 1
normalized_coeff = coeff / sum_coeff
# This means that if DC is sent in, the amplification is 1
# Now, move the "DC" frequency to the frequency we are interested in.
normalized_coeff *= h_cos(n)

print("-----------------------")
print("Coefficients:")
print("-----------------------")
print(coeff)
print("min: ", min(coeff), ", max: ", max(coeff))

# Print information about the normalized coefficients
print("-----------------------")
print("Normalized coefficients:")
print("-----------------------")
print(normalized_coeff)
print("min: ", min(normalized_coeff), ", max: ", max(normalized_coeff))

# Send 1 bit in to the multiplier, to never saturate
print("-----------------------")
print("Quantized coefficients")
print("-----------------------")
quantized_coeff = Fxp(
    normalized_coeff,
    signed=True,
    n_word=FPGA_MULTIPLIER_NUM_BITS,
    n_frac=FPGA_MULTIPLIER_NUM_BITS - 1,
    rounding="floor",
)
print(quantized_coeff.info(verbose=3))
print(quantized_coeff)
print("min: ", min(quantized_coeff), ", max: ", max(quantized_coeff))
print(len(quantized_coeff))

# Find the maximum and minimum value the output of the filter can have
max_val = 0
min_val = 0
for val in quantized_coeff:
    if val > 0:
        max_val += val
    else:
        min_val += val

print("minimum and max value of filter coefficients: ", min_val, max_val)

ax[1].set_title("Koeffisienter")
ax[1].set_xlabel("Samplingspunkter")
ax[1].stem(samples, normalized_coeff, "C0", label="Python presisjon")
ax[1].stem(samples, quantized_coeff, "C1", label="Kvantisert")

ax[1].set_ylim(min(normalized_coeff) * 1.1, max(normalized_coeff) * 1.1)
# ax[1].set_ylim(-0.01, 0.01)


# Write coefficients to file
num_bits_as_binary = FPGA_MULTIPLIER_NUM_BITS % 4
with open(f"coefficients_{ORDER}_vhdl_format.txt", "w") as f:
    for i, coeff in enumerate(quantized_coeff):
        i = i + 1
        if num_bits_as_binary != 0:
            val = int(coeff.hex()[2], 16)
            formatted_val = '"{1:0{0}b}"&'.format(num_bits_as_binary, val)
            f.write(formatted_val)
        f.write(f'x"{coeff.hex()[3:]}", ')
        if i % 16 == 0:
            f.write("\n")

print(quantized_coeff)

# Generer støy
rng = np.random.default_rng()

noise_power = 0.001 * F_s / 2
w = rng.normal(scale=np.sqrt(noise_power), size=t.shape)

# Quantize noise, to prove that number of bits to generate noise from LFSR does not matter
# If the period is long (number of bits in LFSR is big)
w_q = Fxp(
    w,
    signed=True,
    n_word=1,  # 1
    n_frac=0,  # 0
    rounding="floor",
)
print(w_q)
# Filter with exact
filtered_output = np.convolve(w_q, normalized_coeff)

f, pxx = signal.welch(filtered_output, F_s, nperseg=2**12)
pxx_db = 10 * np.log10(pxx)

ax[2].set_title("Støy teoretisk sendt igjennom filteret")
ax[2].set_xlabel("Frekvens (Hz)")
ax[2].set_ylabel("Amplitude (dB)")
ax[2].plot(f, pxx_db - max(pxx_db), label="Filtrert støy")
ax[2].plot([f[0], f[-1]], [-3, -3], color="red", alpha=0.5, label="-3dB")


# Quantized
filtered_output_quantized = np.convolve(w_q, quantized_coeff)
output_min, output_max = min(filtered_output_quantized), max(filtered_output_quantized)

# filtered_output_quantized += (output_max + np.abs(output_min)) / 2

f, pxx = signal.welch(filtered_output_quantized, F_s, nperseg=2**12)
pxx_db = 10 * np.log10(pxx)
ax[2].plot(f, pxx_db - max(pxx_db), "--", label="Kvantisert filtrert støy")
# ax[2].plot([f[0], f[-1]], [-3,-3], "--", color="red")
# ax[2].plot(np.fft.fft(f(x)))
# ax[2].plot(np.fft.fft(sinc(x)))

# Step response
# t = np.arange(0, 1, 1 / F_s)

# step = 2 * (np.cos(2 * np.pi * 2880 * t) > 0.0) - 1

# filtered_output = np.convolve(step, normalized_coeff)

# f, pxx = signal.welch(filtered_output, F_s, nperseg=2**12)
# pxx_db = 10 * np.log10(pxx)
# ax[2].plot(f, pxx_db - max(pxx_db), color="purple")

# ax[3].plot(step)
# ax[3].plot(filtered_output)

for ax in fig.get_axes():
    ax.legend()
    ax.grid()


plt.show()
