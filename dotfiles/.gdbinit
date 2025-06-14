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

# Pretty printer hooks
add-auto-load-safe-path ~/qbm/cpp-template/etc/gdb/absl_pretty_printers.py
source ~/qbm/cpp-template/etc/gdb/absl_pretty_printers.py

add-auto-load-safe-path ~/qbm/cpp-template/etc/gdb/libstdcxx_pretty_printers.py
source ~/qbm/cpp-template/etc/gdb/libstdcxx_pretty_printers.py

