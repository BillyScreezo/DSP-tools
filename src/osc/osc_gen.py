#
# Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
# See LICENSE file for licensing details.
#
# This file contains exporting the sin/cos table to a text file
#

import matplotlib.pyplot as plt
import numpy as np
import math

plt.close()

def twos_complement(n, bits=16):
    mask = (1 << bits) - 1
    if n < 0:
        n = ((abs(n) ^ mask) + 1)
    return n & mask

# ===============================================
# ====================== Generation parameters
# ===============================================

r  = 16                     # Bit depth of the data
fname = 'export_osc.csv'    # Table export file

fs = int(50)                # Sampling frequency
f_osc = int(40)             # Generator frequency
phi_0 = np.pi/12            # Initial signal phase

# ===============================================
# ====================== Generator
# ===============================================

lcm = math.lcm(fs, f_osc)

N = int(lcm/f_osc)

print(f'Table size is: {N}')
    
ph = np.array([(2 * np.pi * f_osc * i)/fs for i in range(N)]) + phi_0


sinT = (-np.sin(ph) * 2**(r-1)).astype(int)
cosT = (np.cos(ph) * 2**(r-1)).astype(int)

for i in range(N):
    sinT[i] = twos_complement(sinT[i])
    cosT[i] = twos_complement(cosT[i])
    
# =============================================================================
#     print(f'Sin: {hex(sinT[i])}')
#     print(f'Cos: {hex(cosT[i])}')
# =============================================================================
    
t = np.arange(0, (N-1)/f_osc, 1/fs)

# =============================================================================
# print(t)
# =============================================================================

plt.plot(t, sinT, 'r*-')
plt.plot(t, cosT, 'b*-')
        
with open(fname, 'w') as f:
    for i in range(N):
        f.write('{:04X}'.format(sinT[i]))
        f.write('{:04X}\n'.format(cosT[i]))
        
