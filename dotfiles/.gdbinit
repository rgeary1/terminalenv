#alias si= stepi
#alias r= info registers
alias bs= info breakpoints
#alias d= disassemble
alias st= backtrace
#alias s= step
#alias n= next

set debuginfod enabled on

# Skip std functions
skip -gfi /usr/include/c++/8/bits/*.h

set history save on
