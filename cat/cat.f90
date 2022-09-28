module cat
  use f90getopt
  implicit none
  
  type :: state
     integer :: unused
     integer :: input_unit
     character(len=1000) :: filename
     logical :: show_ends
     logical :: show_tabs
  end type state

contains

  subroutine setup(self)
    type (state) :: self
    type (option_s) :: opts(2)

    opts(1) = option_s("show-ends", .false., "E")
    opts(2) = option_s("show-tabs", .false., "T")

    do
       select case(getopt("ET", opts))
       case(char(0)) ! All options processed
          exit
       case("E")
          self%show_ends = .true.
       case("T")
          self%show_tabs = .true.
       end select
    end do

  end subroutine setup

  function simple_cat(self) result(success)
    type (state) :: self
    logical :: success
    character(len=1) :: tmp
    integer :: reason

    do

       read (unit=self%input_unit, iostat=reason) tmp
       if (reason > 0) then
          call perror(self%filename)
          success = .false.
          return
       else if (reason < 0) then
          success = .true.
          return
       end if

       if (self%show_tabs .and. tmp == char(9)) then
          write(12) "^"
          tmp = "I"
       end if

       if (self%show_ends .and. tmp == new_line('a')) then
          write(12) "$"
       end if

       write(12) tmp

    end do

  end function simple_cat

end module cat

program main
  use f90getopt
  use cat
  implicit none

  type(state) :: self
  integer(4) :: argind
  logical :: ok
  character(1024) :: stdout_filename

  inquire(6, name = stdout_filename)
  open(12, file = stdout_filename, access = 'stream', action = 'write')
  close(6)
  close(5)
  
  call setup(self)

  ok = .true.
  argind = optind
  self%filename = "-"

  do
     if (argind <= iargc()) then
        call get_command_argument(argind, self%filename)
     end if

     self%input_unit = 9 ! first free unit id
     if (self%filename == "-") then
        self%filename = "/dev/stdin"
     end if

     open(unit=self%input_unit, file=self%filename, access='STREAM', form='UNFORMATTED', readonly)

     if (simple_cat(self)) then
        ok = .false.
     end if

     if (self%input_unit /= 5) then
        close(unit=self%input_unit)
     end if

     argind = argind + 1
     if (argind > iargc()) then
        call exit(merge(0, 1, ok))
     end if
  end do

 
end program
