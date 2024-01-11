#
# Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
# See LICENSE file for licensing details.
#
# This file contains checking pid values for random phase
#

from math import ceil

# ADC freq
fs = 50

# PID params
pid_Ku = 0.03
pid_Tu = 1.915e-6
T = 1 / (fs * 1e6)
pid_Kp = 0.6 * pid_Ku                 # Proportional block coefficient
pid_Ki = 1.2 * (pid_Ku / pid_Tu) * T  # Integral block coefficient
pid_Kd = 0.00 * pid_Ku * (pid_Tu / T) # Differential block coefficient
pid_IntMax = 1

# PID decimal coeff to hex
q = 16 # PHASE_SOLVER_WIDTH + 1
pid_Kph = int(ceil(pid_Kp * 2**(q-1)))
pid_Kih = int(ceil(pid_Ki * 2**(q-1)))
pid_Kdh = int(ceil(pid_Kd * 2**(q-1)))

pid_max = int(ceil(pid_IntMax * 2**(q-1)))-1
print(f'PID_dec: Kp: {pid_Kp}, Ki: {pid_Ki}, Kd: {pid_Kd}\n')
print(f'PID for module: K_PROD: {pid_Kph}, K_INT: {pid_Kih}, K_DIFF: {pid_Kdh}, INT_MAX: {pid_max}')