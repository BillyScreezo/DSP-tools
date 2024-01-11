#
# Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
# See LICENSE file for licensing details.
#
# This file contains exporting the sin table to a text file
#

import numpy as np

def twos_complement(n, bits=16):
    mask = (1 << bits) - 1
    if n < 0:
        n = ((abs(n) ^ mask) + 1)
    return n & mask

q  = 10 # Bit depth of the table
r  = 16 # Bit depth of the data

# NCO phase
a = (np.linspace(0, 2**q - 1, 2**q)).astype(int)
k = np.pi / (2 * ((2**q) - 1))

# Sin(phase) array
sinA = (np.sin(k * a) * 2**(r-1)).astype(int)
sinA[-1] = sinA[-2] 

# Reverse sin array
sinA_rev = sinA[::-1]
        
with open('export_nco_sin.csv', 'w') as f:
    for i in range(len(a)):
        f.write('{:04X}'.format(sinA[i]))
        f.write('{:04X}\n'.format(sinA_rev[i]))
        
