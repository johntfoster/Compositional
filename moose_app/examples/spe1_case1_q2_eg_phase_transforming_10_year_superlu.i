# Official-horizon SPE1 Case 1 CG/EG nonequilibrium production deck.
!include spe1_case1_q2_eg_phase_transforming_report.i
!include ../input/includes/schedules/spe1_case1_opm_flow_2021_10_time_sequence.i
!include ../input/templates/distributed_superlu_q2_eg.i

[Outputs]
  # The report overlay's sampled CSV fields provide the spatial evidence for
  # this long run without retaining a large transient Exodus database.
  exodus := false
[]
