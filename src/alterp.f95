! DECK ALTERP
!     This is a modified version of the f77 code written by Alain Hebert.
!     The array 'WK' is used as an argument in order to avoid allocation
!     in Fortran, since this can cause problem with the '.Fortran' 
!     R interface.        

SUBROUTINE ALTERP(LCUBIC, N, X, VAL, LDERIV, TERP, WK)
  !
  ! Purpose: 
  !   
  !    determination of the TERP interpolation/derivation components
  !    using the order 4 Ceschino method with cubic Hermite polynomials.
  !
  ! Copyright:
  !
  !    Copyright (C) 2006 Ecole Polytechnique de Montreal This library
  !    is free software; you can redistribute it and/or modify it under
  !    the terms of the GNU Lesser General Public License as published
  !    by the Free Software Foundation; either version 2.1 of the
  !    License, or (at your option) any later version
  !
  ! Author(s): Alain Hebert
  !
  ! Parameters: input
  !
  !  LCUBIC  = .TRUE.: cubic Ceschino interpolation; 
  !          = .FALSE: linear Lagrange interpolation.
  !  N       number of points.
  !  X       abscissas
  !  VAL     abscissa of the interpolated point.
  !  LDERIV  set to .true. to compute the first derivative with respect
  !          to X. Set to .false. to interpolate.
  ! 
  ! Parameters: output
  !
  !  TERP    interpolation/derivation components.
  !
  !-----------------------------------------------------------------------
  !
  !
  !   SUBROUTINE ARGUMENTS
  !   
  implicit NONE
  integer N, LCUBIC, LDERIV
  double precision X(N), VAL, TERP(N), WK(3, N)

  !  
  ! LOCAL VARIABLES
  !  
  integer I0, I, J, IMIN, IMAX
  double precision DX, HP, HM, GAR, PMX, H1, H2, H3, H4, TEST
  double precision U, YLAST
  
  I0 = 0
  if (N .LE. 1) return
  
  if (N .EQ. 2) then
     if (LDERIV .GT. 0) then
        TERP(1) = -1.0 / (X(2) - X(1))
        TERP(2) = 1.0 / (X(2) - X(1))
     else
        TERP(1) = (X(2) - VAL) / (X(2) - X(1))
        TERP(2) = 1.0 - TERP(1)
     end if
     return
  end if
  
  do I = 1, N
     WK(3, I) = 0.0
     TERP(I) = 0.0
  end do
  
  !
  !     Interval identification: find I0 and compute DX
  !

  do I = 1, N-1
     if ((VAL .GE. X(I)) .and. (VAL .LE. X(I + 1))) then
        I0 = I
        DX = X(I0 + 1) - X(I0)
        exit
     end if
  end do
  
  !
  !     LINEAR LAGRANGE POLYNOMIAL.
  !

  if (LCUBIC .LE. 0) then
     if (LDERIV .GT. 0) then
        TERP(I0) = -1.0 / DX
        TERP(I0 + 1) = 1.0 / DX
     else
        TERP(I0) = (X(I0 + 1) - VAL) / DX
        TERP(I0 + 1) = 1.0 - TERP(I0)
     end if
     return
  end if
  
  !
  !     CESCHINO CUBIC POLYNOMIAL.
  !

  U = (VAL - 0.5 * (X(I0) + X(I0 + 1))) / DX
  
  if (LDERIV .GT. 0) then
     H1 = (-6.0 * (0.5 - U) + 6.0 * (0.5 - U)**2) / DX
     H2 = (-2.0 * (0.5 - U) + 3.0 * (0.5 - U)**2) / DX
     H3 = (6.0 * (0.5 + U) - 6.0 * (0.5 + U)**2) / DX
     H4 = (-2.0 * (0.5 + U) + 3.0 * (0.5 + U)**2) / DX
     TEST = 0.0
  else
     H1 = 3.0 * (0.5 - U)**2 - 2.0 * (0.5 - U)**3
     H2 = (0.5 - U)**2 - (0.5 - U)**3
     H3 = 3.0 * (0.5 + U)**2 - 2.0 * (0.5 + U)**3
     H4 = -(0.5 + U)**2 + (0.5 + U)**3
     TEST = 1.0
  end if
  
  TERP(I0) = H1
  TERP(I0 + 1) = H3
  WK(3, I0) = H2 * DX
  WK(3, I0 + 1) = H4 * DX
  
  !
  !     COMPUTE THE COEFFICIENT MATRIX.
  !     

  HP = 1.0 / (X(2) - X(1))
  WK(1, 1) = HP
  WK(2, 1) = HP
  
  do I = 2, N-1
     HM = HP
     HP = 1.0 / (X(I + 1) - X(I))
     WK(1, I) = 2.0 * (HM + HP)
     WK(2, I) = HP
  end do
  
  WK(1,N) = HP
  WK(2,N) = HP
  
  !
  !     FORWARD ELIMINATION.
  !     

  PMX = WK(1, 1)
  WK(3, 1) = WK(3, 1) / PMX
  
  do I = 2, N
     GAR = WK(2, I - 1)
     WK(2, I - 1) = WK(2, I - 1) / PMX
     PMX = WK(1, I) - GAR * WK(2, I - 1)
     WK(3, I) = (WK(3, I) - GAR * WK(3, I - 1)) / PMX
  end do
  
  !
  !     BACK SUBSTITUTION.
  !

  do I = N-1, 1, -1
     WK(3, I) = WK(3, I) - WK(2, I) * WK(3, I + 1)
  end do
  
  !
  !     COMPUTE THE INTERPOLATION FACTORS.
  !

  do J = 1, N
     
     IMIN = MAX(2, J - 1)
     IMAX = MIN(N - 1, J + 1)
     
     do I = 1, N
        WK(1, I) = 0.0
     end do
     
     WK(1, J) = 1.0
     HP = 1.0 / (X(IMIN) - X(IMIN - 1))
     YLAST = WK(1, IMIN - 1)
     WK(1, IMIN - 1) = 2.0 * HP * HP * &
          (WK(1, IMIN) - WK(1, IMIN - 1))
     
     do  I = IMIN, IMAX
        HM = HP
        HP = 1.0/(X(I + 1) - X(I))
        PMX = 3.0 * (HM * HM * (WK(1, I) - YLAST) + &
             HP * HP * (WK(1, I + 1) - WK(1, I)))
        YLAST = WK(1, I)
        WK(1, I) = PMX
     end do
     
     WK(1, IMAX + 1) = 2.0 * HP * HP * (WK(1, IMAX + 1) - YLAST)
     
     do I = IMIN - 1, IMAX + 1
        TERP(J) = TERP(J) + WK(1, I) * WK(3, I)
     end do
     
     if (ABS(TERP(J)) .LE. 1.0E-7) TERP(J) = 0.0
     
     TEST = TEST - TERP(J)
     
  end do
  
  if (ABS(TEST) .GT. 1.0E-5) return
  
  return
  
end SUBROUTINE ALTERP
