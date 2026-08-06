# Shared total stock-tank oil rate used by the AD completion aggregation
# equation. The datum BHP scalar is supplied by fields.spe2_black_oil_q2_eg.
[Variables]
  [producer_oil_rate_scalar]
    family = SCALAR
    order = FIRST
    initial_condition = 0.0018401307283333335
    scaling = 500
  []
[]
