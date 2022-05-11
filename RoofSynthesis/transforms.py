import numpy as np

import torch
import torch.nn.functional as F

class Centroid(object):
    def __init__(self, scale=False, rotate=False, infer=False, jitter=False, flip=False):
        self.scale = scale
        self.rotate = rotate
        self.infer = infer
        self.jitter = jitter
        self.flip = flip

    def __call__(self, data):
        with torch.no_grad():
            v = data

            if self.rotate:
                if self.infer:
                    theta = 0.3 * 2 * np.pi
                else:
                    theta = np.random.randint(4) / 2.0 * np.pi
                transformation = np.array([[np.cos(theta), -np.sin(theta)], [np.sin(theta), np.cos(theta)]])
                transformation = torch.from_numpy(transformation.astype(np.float32))
                v = torch.matmul(v, transformation)

            max = torch.max(v, dim=0)[0]
            min = torch.min(v, dim=0)[0]

            v = (v - min[None]) / (max[None]- min[None]) * 2 - 1

            if self.flip:
                if torch.rand(1) < 0.5:
                    v = torch.flip(v, (0,1))

            if self.jitter:

                v += torch.randn_like(v) * 0.02
                v.clamp_(min=-1.0, max=1.0)

            if self.scale:
                if self.infer:
                    scale = 0.7
                else:
                    scale = np.random.rand() * 0.3 + 0.6
                v *= scale
            v = v / 2 + 0.5

        return v

    def __repr__(self):
        return '{}'.format(self.__class__.__name__)

class Shuffle(object):
    def __init__(self):
        pass
    
    def __call__(self, data):
        
        # # print(data)
        # i = np.random.randint(data.shape[0])
        # data = torch.roll(data, i, 0)
        # # print(data)
        return data

class Flatten(object):
    def __init__(self, quantize_bits=6):
        self.quantize_bits = quantize_bits
    
    def __call__(self, data):

        range_quantize = 2**self.quantize_bits - 1
        data *= range_quantize
        data = data.long() + 1

        value, _ = torch.min(data[:, 0], dim=0)

        clone = data.clone()
        clone[data[:, 0] != value, :] = 2**10
        i = torch.argmin(clone[:, 1], dim=0).item()
        
        if i < data.shape[0]-1:
            if data[i+1, 0] == data[i, 0]:
                assert data[i+1, 1] >= data[i, 1]
        data = torch.roll(data, -i, 0)


        data = data.view(-1)# * range_quantize
        data = torch.cat([torch.Tensor([0]).long(), data, torch.Tensor([0]).long()], dim=0)

        return data