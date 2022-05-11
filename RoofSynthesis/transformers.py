import math

import torch
import torch.nn as nn
import torch.nn.functional as F

# def generate_square_subsequent_mask(sz: int) -> torch.Tensor:
#     r"""Generate a square mask for the sequence. The masked positions are filled with float('-inf').
#         Unmasked positions are filled with float(0.0).
#     """
#     mask = (torch.triu(torch.ones(sz, sz)) == 1).transpose(0, 1)
#     mask = mask.float().masked_fill(mask == 0, float('-inf')).masked_fill(mask == 1, float(0.0))
#     return mask

class PositionalEncoding(nn.Module):
    r"""Inject some information about the relative or absolute position of the tokens
        in the sequence. The positional encodings have the same dimension as
        the embeddings, so that the two can be summed. Here, we use sine and cosine
        functions of different frequencies.
    .. math::
        \text{PosEncoder}(pos, 2i) = sin(pos/10000^(2i/d_model))
        \text{PosEncoder}(pos, 2i+1) = cos(pos/10000^(2i/d_model))
        \text{where pos is the word position and i is the embed idx)
    Args:
        d_model: the embed dim (required).
        dropout: the dropout value (default=0.1).
        max_len: the max. length of the incoming sequence (default=5000).
    Examples:
        >>> pos_encoder = PositionalEncoding(d_model)
    """

    def __init__(self, d_model, dropout=0.1, max_len=5000):
        super(PositionalEncoding, self).__init__()
        self.dropout = nn.Dropout(p=dropout)

        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-math.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0).transpose(0, 1)
        self.register_buffer('pe', pe)

    def forward(self, x):
        r"""Inputs of forward function
        Args:
            x: the sequence fed to the positional encoder model (required).
        Shape:
            x: [sequence length, batch size, embed dim]
            output: [sequence length, batch size, embed dim]
        Examples:
            >>> output = pos_encoder(x)
        """

        x = x + self.pe[:x.size(0), :]
        return self.dropout(x)

class TransformerModel(nn.Module):
    """Container module with an encoder, a recurrent or transformer module, and a decoder."""

    def __init__(self, ntoken, ninp, nhead, nhid, nlayers, dropout=0.5):
        super(TransformerModel, self).__init__()

        self.src_mask = None
        self.positional = PositionalEncoding(ninp, dropout)
        encoder_layers = nn.TransformerEncoderLayer(ninp, nhead, nhid, dropout)
        self.transformer_encoder = nn.TransformerEncoder(encoder_layers, nlayers)
        self.vertex_encoder = nn.Embedding(ntoken, ninp)
        self.pos_encoder = nn.Embedding(50, ninp) # 50
        self.ind_encoder = nn.Embedding(2, ninp)
        self.ninp = ninp
        # self.decoder = nn.Linear(ninp, ntoken)

        self.drop = nn.Dropout(dropout)

        self.init_weights()

    def _generate_square_subsequent_mask(self, sz):
        mask = (torch.triu(torch.ones(sz, sz)) == 1).transpose(0, 1)
        mask = mask.float().masked_fill(mask == 0, float('-inf')).masked_fill(mask == 1, float(0.0))
        return mask

    # def init_weights(self):
    #     initrange = 0.1
    #     nn.init.uniform_(self.vertex_encoder.weight, -initrange, initrange)
    #     nn.init.uniform_(self.pos_encoder.weight, -initrange, initrange)
    #     nn.init.uniform_(self.ind_encoder.weight, -initrange, initrange)
    #     # nn.init.zeros_(self.decoder.weight)
    #     # nn.init.uniform_(self.decoder.weight, -initrange, initrange)

    def init_weights(self):
        """ Initialize and prunes weights if needed. """
        # Initialize weights
        self.apply(self._init_weights)

    def _init_weights(self, module):
        """ Initialize the weights.
        """
        if isinstance(module, (nn.Linear, nn.Embedding, nn.Conv1d)):
            # Slightly different from the TF version which uses truncated_normal for initialization
            # cf https://github.com/pytorch/pytorch/pull/5617
            module.weight.data.normal_(mean=0.0, std=0.01)
            if isinstance(module, (nn.Linear, nn.Conv1d)) and module.bias is not None:
                module.bias.data.zero_()
        elif isinstance(module, nn.LayerNorm):
            module.bias.data.zero_()
            module.weight.data.fill_(1.0)

    def forward(self, src, has_mask=True):
        # print(src[:, 0])
        src = self.vertex_encoder(src)# * math.sqrt(self.ninp)
        # print(src.shape)

        ids = torch.arange(1, src.shape[0]+1).long().to(src.device)       
        ind_ids = torch.remainder(ids, 2)
        src += self.ind_encoder(ind_ids)[:, None]

        pos_ids = ((ids) / 2).floor().long()
        # print(ids.dtype, pos_ids.dtype)
        src += self.pos_encoder(pos_ids)[:, None]

        # src = self.positional(src)

        # zero_embed_tiled = torch.zeros(1, src.shape[1], src.shape[2]).to(src.device)
        # # print(src.shape)
        # src = torch.cat([zero_embed_tiled, src], dim=0)
        # # print(src.shape)

        if has_mask:
            device = src.device
            # print(src.shape)
            if self.src_mask is None or self.src_mask.size(0) != len(src):
                mask = self._generate_square_subsequent_mask(len(src)).to(device)
                self.src_mask = mask
        else:
            self.src_mask = None

        src = self.drop(src)

        # print(src.shape)
        output = self.transformer_encoder(src, self.src_mask)
        # output = self.decoder(output)
        output = torch.matmul(output, self.vertex_encoder.weight.transpose(0, 1))
        return output#[1:]
        # return F.log_softmax(output, dim=-1)

if __name__ == '__main__':
    # encoder_layer = nn.TransformerEncoderLayer(d_model=512, nhead=8)
    # transformer_encoder = nn.TransformerEncoder(encoder_layer, num_layers=6)
    # src = torch.rand(10, 1, 512)
    # mask = generate_square_subsequent_mask(10)
    # out = transformer_encoder(src, mask)
    # print(out.shape)
    m = TransformerModel(257, 512, 8, 128, 6, 0.2)
    i = torch.rand(50, 10) * 256
    i = i.long()
    print(m(i, has_mask=True).shape)