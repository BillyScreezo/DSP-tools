#
# Copyright (C) 2024 Kirill Turintsev <billiscreezo228@gmail.com>
# See LICENSE file for licensing details.
#
# This file contains pipeline implementation of PID controller
#

import numpy as np
import math

#################################################
############## PID
#################################################
    
class pidPipe(object):
    def __init__(self, set_point : np.single, Kp : np.single, Ki : np.single, Kd : np.single, Int_max : np.single, pipe_size : np.ushort):
        self.Ival = 0
        self.Der  = 0

        self.set_point = set_point
        self.Kp = Kp
        self.Ki = Ki
        self.Kd = Kd
        self.Int_max = Int_max
        
        self.pipe = np.zeros(pipe_size, dtype=np.single)

    def update(self, val : np.single):
        ret = self.pipe[-1]
        
        error = self.set_point - val

        Pval = error

        self.Ival = self.Ival + error
        if self.Ival > self.Int_max:
            self.Ival = self.Int_max
        elif self.Ival < -self.Int_max:
            self.Ival = -self.Int_max

        Dval = (error - self.Der)
        self.Der = error
        
        self.pipe = np.roll(self.pipe, 1)
        self.pipe[0] = self.Kp * Pval + self.Ki * self.Ival + self.Kd * Dval
        

        return ret