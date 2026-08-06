# Bounded official-grid SPE1 Case 1 regression through the fifth pinned
# TSTEP reporting boundary: 151 days = 13,046,400 seconds.  The time sequence
# reproduces the accepted internal steps reported by pinned OPM Flow 2021.10.
!include ../../../examples/spe1_case1_transient_fv.i
!include ../../../input/includes/schedules/spe1_case1_opm_flow_2021_10_time_sequence.i

[Times]
  [first_five_official_reports]
    type = InputTimes
    times = '2678400 5097600 7776000 10368000 13046400'
  []
[]

[Outputs]
  [monthly_csv]
    type = CSV
    sync_only = true
    sync_times_object = first_five_official_reports
  []
[]
