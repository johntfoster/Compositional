# SPE2 production schedule in SI units. Time is measured from the published
# origin, so the four breakpoints are days 1, 10, 50, and 720.
[Functions]
  [spe2_oil_rate_schedule]
    type = PiecewiseConstant
    x = '86400 864000 4320000 62208000'
    y = '0.0018401307283333335 0.00018401307283333335 0.0018401307283333335 0.00018401307283333335'
    direction = left_inclusive
  []
[]
