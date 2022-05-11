import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim

import torchvision.transforms as T

import numpy as np

from tqdm import tqdm

import matplotlib.pyplot as plt

from dataset import Outline
from transforms import Centroid, Flatten, Shuffle
from transformers import TransformerModel

def pad_sequence(sequences, batch_first=False, padding_value=int(-1)):
    max_size = sequences[0].size()
    trailing_dims = max_size[1:]
    max_len = max([s.size(0) for s in sequences])# + 1
    # max_len = 50
    if batch_first:
        out_dims = (len(sequences), max_len) + trailing_dims
    else:
        out_dims = (max_len, len(sequences)) + trailing_dims

    out_tensor = sequences[0].new_full(out_dims, padding_value)
    for i, tensor in enumerate(sequences):
        length = tensor.size(0)
        # use index notation to prevent duplicate references to the tensor
        if batch_first:
            out_tensor[i, :length, ...] = tensor
        else:
            out_tensor[:length, i, ...] = tensor

    return out_tensor

bits = int(6)

train_dataset = Outline(root='./data', split='train', transform=T.Compose([Centroid(rotate=True, infer=False, scale=False, jitter=False, flip=True), Flatten(quantize_bits=bits)]))
train_loader = torch.utils.data.DataLoader(train_dataset, batch_size=32, shuffle=True, collate_fn=pad_sequence)

test_dataset = Outline(root='./data', split='test', transform=T.Compose([Centroid(rotate=False, infer=True, scale=False), Flatten(quantize_bits=bits)]))
test_loader = torch.utils.data.DataLoader(test_dataset, batch_size=1, shuffle=False, collate_fn=pad_sequence)

net = TransformerModel(2**bits+1, 384, nhead=12, nhid=384*4, nlayers=6, dropout=0.3) #6, 0.3

device = 'cuda:0'
net = net.to(device)
optimizer = optim.Adam(net.parameters(), lr=0.0002)

for e in range(100): #100
    losses = []

    data_stream = tqdm(enumerate(train_loader))
    
    net.train()

    for iter, data in data_stream:
        data = data.to(device)
        input = data[:-1].clone()
        input[input==-1] = 0

        output = net(input, has_mask=True)
        loss = F.cross_entropy(output.view(-1, 2**bits+1), data[1:].view(-1), ignore_index=-1)

        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        losses.append(loss.item())
        data_stream.set_description('[TRAIN] [{:05d}/{:05d}] {:03d} {:.6f}({:.6f})'.format(iter, len(train_loader), e, loss.item(), np.mean(losses)))

    net.eval()
    with torch.no_grad():
        losses = []

        data_stream = tqdm(enumerate(test_loader))

        for iter, data in data_stream:
            data = data.to(device)
            input = data[:-1].clone()
            input[input==-1] = 0
            output = net(input, has_mask=True)
            loss = F.cross_entropy(output.view(-1, 2**bits+1), data[1:].view(-1), ignore_index=-1)

            losses.append(loss.item())
        print(np.mean(losses))

torch.save(net.state_dict(), 'checkpoint.pth.{}'.format(bits))

# net.eval()
# for e in tqdm(range(100)):
#     with torch.no_grad():
#         iter = 0
#         next_sample = torch.ones(1)
#         max_iter = 100
#         # samples = torch.zeros([1]).long().to(device)
#         samples = torch.Tensor([0]).long().to(device)

#         while next_sample.item() != 0 and iter < max_iter:
#         # while iter < max_iter:
#             output = net(samples[:, None], has_mask=False)[-1].view(-1)
#             probs = F.softmax(output, dim=0)
#             next_sample = torch.multinomial(probs, 1)#.float()
#             samples = torch.cat([samples, next_sample], dim=0)
#             iter += 1
#         # print(probs.max(), probs.mean(), probs.min())
#         # print(samples)
#         # print(len(samples))

#         samples = samples[1:-1]
#         if samples.shape[0] % 2 == 1:
#             samples = samples[:-1]


#         verts = (samples - 1) / 63.0
#         verts = verts.view(-1, 2)
#         # print(verts)

#         verts = verts.cpu().detach().numpy()
#         plt.figure(figsize=(5,5))
#         plt.fill(verts[:, 0], verts[:, 1])
#         plt.savefig('{:04d}.png'.format(e), dpi=300, format='png', bbox_inches='tight')
#         plt.close()