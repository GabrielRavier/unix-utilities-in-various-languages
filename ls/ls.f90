module ls

  implicit none

  type :: state
     integer :: format
  end type

  enum, bind(c)

     enumerator :: one_per_line = 0, many_per_line = 1

  endenum

contains

  function isatty_stdout() result(out_tty)
    integer :: out_tty
    out_tty = 1
  end function

  subroutine setup(self)
    type(state) :: self

    self%format = isatty_stdout()

  end subroutine

end module ls

program main
  use ls
  implicit none

  type(state) :: self
  call setup(self)
  print *, self%format
end program
