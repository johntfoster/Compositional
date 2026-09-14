# Sun, Ostien, and Salinger 2013, stabilized finite-strain poromechanics

## Source

- PDF: `references/pdfs/sun-ostien-salinger-2013-stabilized-finite-strain-poromechanics.pdf`
- BibTeX key: `sun2013stabilized`
- DOI: `10.1002/nag.2161`

## Support used by the Mandel implementation report

- Section 3 presents a total-Lagrangian weighted-residual formulation for a
  coupled displacement--pressure finite-element problem.
- Section 4, PDF pages 15--16, describes evaluators templated on scalar type.
  The same residual evaluation supplies either values or automatic derivatives,
  so changes to residual code propagate to the Jacobian.
- The paper discusses inf-sup-stable displacement--pressure spaces and the
  stabilization needed for equal-order alternatives. It does not prescribe the
  Q2/Q1 choice used in the present Mandel deck.

## Citation role

Use this source for the finite-deformation mixed finite-element and
residual-based automatic-differentiation implementation strategy. Use Foster
and Xu for the nonlinear Biot-coefficient definition and Cheng and Detournay
for the analytical Mandel pressure series.
