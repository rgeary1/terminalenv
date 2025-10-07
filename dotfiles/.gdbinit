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

#############################
# qcore

skip function Bytes::Bytes()
skip function Bytes::Bytes(const void*, size_t)
skip function Bytes::Bytes(const char*, const char*)
skip file qcore/mem/BytesBuf.h
#skip file /opt/infra.1/include/c++/15.1.0/bits/std_function.h
skip file qbuild/Callback.h
skip file /home/richard/qbm/cpp-template/3rdparty/install/*


# Pretty printer hooks
add-auto-load-safe-path ~/qbm/core/etc/gdb/absl_pretty_printers.py
source ~/qbm/core/etc/gdb/absl_pretty_printers.py

add-auto-load-safe-path ~/qbm/core/etc/gdb/libstdcxx_pretty_printers.py
source ~/qbm/core/etc/gdb/libstdcxx_pretty_printers.py

