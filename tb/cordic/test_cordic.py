#
# Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
# See LICENSE file for licensing details.
#
# This file contains signal generator for Cordic tb module
#

import numpy as np
import matplotlib.pyplot as plt
import math

def twos_complement(n, bits=16):
    mask = (1 << bits) - 1
    if n < 0:
        n = ((abs(n) ^ mask) + 1)
    return n & mask

re_u = np.linspace(-1, 1, 200)
re_d = np.linspace(1, -1, 200)

im_u = np.sqrt(1 - re_u**2);
im_d = -np.sqrt(1 - re_d**2);

re_u[-1] = re_u[-2]
re_d[0] = re_d[1]

accurancy = 10 # CORDIC accurancy

re_uw = [int(re_u[i] * 2**(accurancy - 1)) for i in range(len(re_u))]
re_dw = [int(re_d[i] * 2**(accurancy - 1)) for i in range(len(re_d))]
im_uw = [int(im_u[i] * 2**(accurancy - 1)) for i in range(len(im_u))]
im_dw = [int(im_d[i] * 2**(accurancy - 1)) for i in range(len(im_d))]

#im_u_wr[0] = im_u_wr[1]
#re_wr[-1] = re_wr[-2]

#plt.plot(re_u, im_u, 'r')
#plt.plot(re_d, im_d, 'b')

plt.plot(re_u, np.angle(re_u + 1j*im_u), 'r')
plt.plot(re_d, np.angle(re_d + 1j*im_d), 'b')

#print(re_d[:])

with open('export_test_vect.csv', 'w') as f:
    for i in range(len(re_uw)):
        f.write('{:};'.format(re_uw[i]))
        f.write('{:}\n'.format(im_uw[i]))
        
    for i in range(len(re_dw)):
        f.write('{:};'.format(re_dw[i]))
        f.write('{:}\n'.format(im_dw[i]))
        
        
# K_MAX
i = np.linspace(0, accurancy-1, accurancy, endpoint=True)
Kn = math.prod(np.sqrt(1+2**(-2*i)))
Kn = 1/Kn
Kn = int(np.floor(Kn * 2**(accurancy-1)))
print(Kn - 1)