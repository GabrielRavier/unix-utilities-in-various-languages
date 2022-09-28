module cat

  implicit none
  
  type :: state
     integer :: unused
     integer :: input_unit
  end type state

contains

  subroutine setup(self)
    type (state) :: self
  end subroutine setup

  function simple_cat(self) result(success)
    type (state) :: self
    logical :: success

    do
       character :: tmp

       read (unit=self%input_unit, end=retlab) character
       print *,character
       
    end do

    retlab:
    success = .true.
    return

  end function simple_cat

end module cat

program main
  use cat
  implicit none

  type(state) :: self
  call setup(self)

  character(len=1000) :: filename
  integer :: argind
  argind = 1

  do
     if (argind < iargc()) then
        get_command_argument(argind, filename)
     end if

     self%input_unit = 9 ! first free unit id
     if (filename == "-") then
        self%input_unit = 5 ! 5 is stdin
     else
        open(unit=self%input_unit, file=filename, access='STREAM', form='UNFORMATTED')
     end if

     simple_cat(self)

     if (self%input_unit /= 5) then
        close(self%input_unit
     end if

  end do
 
end program
