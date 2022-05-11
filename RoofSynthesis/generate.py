import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim

import torchvision.transforms as T

import numpy as np

from tqdm import tqdm

import matplotlib.pyplot as plt

from shapely.geometry import Polygon

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
bits = 6

# train_dataset = Outline(root='./data', split='train', transform=T.Compose([Centroid(rotate=True, infer=False, scale=False, jitter=False, flip=False), Shuffle(), Flatten(quantize_bits=bits)]))
# train_loader = torch.utils.data.DataLoader(train_dataset, batch_size=32, shuffle=True, collate_fn=pad_sequence)

# test_dataset = Outline(root='./data', split='test', transform=T.Compose([Centroid(rotate=False, infer=True, scale=False), Flatten(quantize_bits=bits)]))
# test_loader = torch.utils.data.DataLoader(test_dataset, batch_size=1, shuffle=False, collate_fn=pad_sequence)

net = TransformerModel(2**bits+1, 384, nhead=12, nhid=384*4, nlayers=6, dropout=0.3) #6, 0.3

device = 'cuda:0'
net = net.to(device)

net.load_state_dict(torch.load('checkpoint.pth.{}'.format(bits)))

class Point(object):
	def __init__(self,x,y):
		self.x = x
		self.y = y

def ccw(A,B,C):
	return (C.y-A.y)*(B.x-A.x) > (B.y-A.y)*(C.x-A.x)

def intersect(A,B,C,D):
	return ccw(A,C,D) != ccw(B,C,D) and ccw(A,B,C) != ccw(A,B,D)

# def top_k_top_p_filtering(logits, top_k=0, top_p=0.0, filter_value=-float('Inf')):
#     """ Filter a distribution of logits using top-k and/or nucleus (top-p) filtering
#         Args:
#             logits: logits distribution shape (vocabulary size)
#             top_k >0: keep only top k tokens with highest probability (top-k filtering).
#             top_p >0.0: keep the top tokens with cumulative probability >= top_p (nucleus filtering).
#                 Nucleus filtering is described in Holtzman et al. (http://arxiv.org/abs/1904.09751)
#     """
#     assert logits.dim() == 1  # batch size 1 for now - could be updated for more but the code would be less clear
#     top_k = min(top_k, logits.size(-1))  # Safety check
#     if top_k > 0:
#         # Remove all tokens with a probability less than the last token of the top-k
#         indices_to_remove = logits < torch.topk(logits, top_k)[0][..., -1, None]
#         logits[indices_to_remove] = filter_value

#     if top_p > 0.0:
#         sorted_logits, sorted_indices = torch.sort(logits, descending=True)
#         cumulative_probs = torch.cumsum(F.softmax(sorted_logits, dim=-1), dim=-1)

#         # Remove tokens with cumulative probability above the threshold
#         sorted_indices_to_remove = cumulative_probs > top_p
#         # Shift the indices to the right to keep also the first token above the threshold
#         sorted_indices_to_remove[..., 1:] = sorted_indices_to_remove[..., :-1].clone()
#         sorted_indices_to_remove[..., 0] = 0

#         indices_to_remove = sorted_indices[sorted_indices_to_remove]
#         logits[indices_to_remove] = filter_value
#     return logits


net.eval()
for e in tqdm(range(361)):
    with torch.no_grad():
        # iter = 0
        next_sample = torch.ones(1)
        # max_iter = 400
        # samples = torch.zeros([1]).long().to(device)
        samples = torch.Tensor([0]).long().to(device)

        points = []

        while next_sample.item() != 0 and samples.shape[0] < 400:
        # while iter < max_iter:
            output = net(samples[:, None], has_mask=False)[-1].view(-1)
            probs = F.softmax(output, dim=0)
            # print(probs.max(), probs.mean(), probs.min())
            # print(probs.topk(k=5)[0])
            # print(probs)

            ## top-k
            top_k = 15
            topk, indices = torch.topk(probs, k=top_k)
            probs = torch.zeros(*probs.shape).to(probs.device).scatter_(0, indices, topk)

            # top-p
            top_p = 0.95
            sorted_probs, sorted_indices = torch.sort(probs, descending=True)
            cumulative_probs = torch.cumsum(sorted_probs, dim=-1)

            sorted_indices_to_remove = cumulative_probs > top_p
            # print(probs.max().item())
            # print('start', sorted_indices_to_remove)
            sorted_indices_to_remove[..., 1:] = sorted_indices_to_remove[..., :-1].clone()
            sorted_indices_to_remove[..., 0] = False
            # print('end', sorted_indices_to_remove)
            indices_to_remove = sorted_indices[sorted_indices_to_remove]
            probs[indices_to_remove] = 0

            # print(probs)

            next_sample = torch.multinomial(probs, 1)#.float()

            # if next_sample.item() == 0:
            #     if samples.shape[0] % 2 == 0:
            #         next_sample = torch.multinomial(probs, 1)
            iter = 0
            # max_iter = 400
            while next_sample.item() == 0:# and iter < max_iter:
                # print(probs.max().item(), samples, next_sample[0], samples.shape[0])
                if samples.shape[0] <= 9:
                    next_sample = torch.multinomial(probs, 1)
                if samples.shape[0] % 2 == 0:
                # elif samples.shape[0] % 2 == 1:
                    next_sample = torch.multinomial(probs, 1)
                else:
                    # break
                    if samples[-1] == samples[2] or samples[-2] == samples[1]:
                        break
                    else:
                        samples = samples[:-2].clone()
                        output = net(samples[:, None], has_mask=False)[-1].view(-1)
                        probs = F.softmax(output, dim=0)
                        next_sample = torch.multinomial(probs, 1)#.float()
                # iter += 1

            # if iter >= max_iter:
            #     continue

                    # if samples[-1] == samples[1]:
                    #     break
                    # else:
                    #     samples = samples[:-1].clone()
                    #     output = net(samples[:, None], has_mask=False)[-1].view(-1)
                    #     probs = F.softmax(output, dim=0)
                    #     next_sample = torch.multinomial(probs, 1)#.float()

            # if samples.shape[0] % 2 == 0:
            #     while next_sample.item() == 0:
            #         next_sample = torch.multinomial(probs, 1)
            # else:
            #     while next_sample.item() == 0 and samples[-1] != samples[2] and samples[-2] != samples[1]:
            #         next_sample = torch.multinomial(probs, 1)


            samples = torch.cat([samples, next_sample], dim=0)
            # iter += 1

        # print(samples, len(samples))
        assert len(samples) % 2 == 0
        # assert len(samples) % 2 == 1
        # print(samples)

        # print(probs.max(), probs.mean(), probs.min())
        # print(samples)
        # print(len(samples))

        samples = samples[1:-1]
        # samples = samples[1:-2]

        # if samples.shape[0] % 2 == 1:
        #     samples = samples[:-1]
        assert torch.all(samples > 0)

        # if samples[-1] == samples[1] or samples[-2] == samples[0]:
        #     pass
        # else:
        #     samples = torch.cat([samples, samples[0:1], samples[-1:]], dim=0)
        #     print(samples)

        verts = (samples - 1) / (2**bits-1)
        verts = verts.view(-1, 2)
        # print(verts)

        if verts.shape[0] <= 4:
            continue

        poly = Polygon(verts)

        if not poly.is_valid:
            continue

        verts = verts.cpu().detach().numpy()

        np.savetxt('generated.{}/{:04d}.outline'.format(bits, e), verts, delimiter=',', fmt='%.06f')

        # verts = np.concatenate([verts, verts[0:1]], 0)
        plt.figure(figsize=(3,3))
        plt.axis('off')
        plt.xlim(-0.1, 1.1)
        plt.ylim(-0.1, 1.1)
        plt.plot(verts[:, 0], verts[:, 1], linewidth=10)
        # plt.plot(verts[-2, 0], verts[-1, 1], linewidth=10)
        plt.plot([verts[0, 0], verts[-1, 0]], [verts[0, 1], verts[-1, 1]], linewidth=10)
        plt.savefig('generated.{}/{:04d}.png'.format(bits, e), dpi=150, format='png', bbox_inches='tight')
        plt.close()
    
    # break