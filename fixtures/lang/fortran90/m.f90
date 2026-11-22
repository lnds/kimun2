module m
! a comment
  !$omp parallel do
!$$ not a directive
print *, "!"
end module
