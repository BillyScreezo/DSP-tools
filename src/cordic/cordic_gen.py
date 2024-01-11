#
# Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
# See LICENSE file for licensing details.
#
# This file contains exporting the generated arctan(2^-i) table to a text file
#

import numpy as np
import math 

# CORDIC accurancy
accurancy   = 16
stages      = 8
fname = 'export_arctan.csv'

powers = [int(np.arctan(2**-i)/np.pi * 2**(accurancy - 1)) for i in range(stages)]

# Export table
with open(fname, 'w') as f:
    for i in range(stages):
        f.write('{:02X}\n'.format(powers[i]))

# Print K
i = np.linspace(0, stages-1, stages, endpoint=True)
Kn = math.prod(np.sqrt(1+2**(-2*i)))
Kn = 1/Kn
Kn = int(np.floor(Kn * 2**(accurancy-1)))
print(f'In the cordic module, assign the K_MAX parameter the value: {Kn - 1}')