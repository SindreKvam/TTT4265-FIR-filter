import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from fxpmath import Fxp

ORDER = 1024
T = 1
F_c = 2880
N = 100000

F_s = 8018  # Lowest sample rate supported by DAC
F_s_inv = 1 / F_s

FPGA_MULTIPLIER_NUM_BITS = 9

# n = np.linspace(-F_s_inv * ORDER, F_s_inv * ORDER, ORDER)
n = np.arange(-F_s_inv * ORDER / 2, F_s_inv * ORDER / 2, F_s_inv)

x = np.linspace(-T, T, N)
t = np.arange(N) / F_s
t_window = np.arange(ORDER) / F_s


def f(t):
    return 1 / (20 * np.pi * t) * np.sin(20 * np.pi * t) * np.cos(2 * np.pi * F_c * t)


def sinc(t):
    return (1 / (20 * np.pi * t)) * np.sin(20 * np.pi * t)


def cos(t):
    return np.cos(F_c * t)


fig, ax = plt.subplots(3, 1)

ax[0].plot(x, f(x))
ax[0].plot(x, sinc(x))

coeff = f(n)
np.nan_to_num(coeff, False, nan=1)  # Remove NaN and replace with 1
sum_coeff = np.sum(coeff)
normalized_coeff = coeff / sum_coeff

print(min(normalized_coeff), max(normalized_coeff))
# min = -16.7, max = 16.6
# This means, we need 6 bits to represent the signed value.
# The rest (10 bits) can represent the fractional

# Multiplier in FPGA supprorts 18 bits.
# Send 1 bit in to the multiplier, to never saturate, sum of

quantized_coeff = Fxp(
    normalized_coeff,
    signed=True,
    n_word=FPGA_MULTIPLIER_NUM_BITS,
    n_frac=FPGA_MULTIPLIER_NUM_BITS - 6,
    rounding="floor",
)
print(quantized_coeff.info(verbose=3))
print(min(quantized_coeff), max(quantized_coeff))


ax[1].stem(t_window, normalized_coeff)
ax[1].stem(t_window, quantized_coeff, "C1")
ax[1].set_ylim(min(normalized_coeff) * 1.1, max(normalized_coeff) * 1.1)

for i, coeff in enumerate(quantized_coeff):
    i = i + 1
    print(f"'{coeff.hex()[2]}'&x\"{coeff.hex()[3:]}\", ", end="")
    if i % 16 == 0:
        print()

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
    n_word=1, # 1
    n_frac=0, # 0
    rounding="floor",
)

# Filter with exact 
filtered_output = np.convolve(w_q, normalized_coeff)

f, pxx = signal.welch(filtered_output, F_s, nperseg=2**12)
pxx_db = 10 * np.log10(pxx)
ax[2].plot(f, pxx_db - max(pxx_db))
ax[2].plot([f[0], f[-1]], [-3,-3], color="red")


# Quantized
filtered_output_quantized = np.convolve(w_q, quantized_coeff)

f, pxx = signal.welch(filtered_output_quantized, F_s, nperseg=2**12)
pxx_db = 10 * np.log10(pxx)
ax[2].plot(f, pxx_db - max(pxx_db), "--")
#ax[2].plot([f[0], f[-1]], [-3,-3], "--", color="red")
# ax[2].plot(np.fft.fft(f(x)))
# ax[2].plot(np.fft.fft(sinc(x)))

plt.show()
