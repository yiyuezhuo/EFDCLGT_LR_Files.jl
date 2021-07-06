
# EFDCLGT_LR_Files.jl

IO related part of the Julia port of [Python version](https://github.com/yiyuezhuo/IWIND-LR-TOOLS).

Implements `save` and `load` mapping for some `EFDCLGT_LR` related Fortran "Card" IO.

While this module tried to implement the `FileIO` interface, the `add_format` would be called from this module so it will violate the standard of the `FileIO`. However, `EFDCLGT_LR` is not a well known program so it's not reasonable to PR them and hijack the `*.inp` extension (Their [doc](https://github.com/JuliaIO/FileIO.jl/blob/bf57b7f62f74b1ed55481684c406ba83415a713b/docs/src/registering.md#argument-magic)  had said something like `.out` should not be registered in `FileIO`). It's strange that Julia encourages such centralization design such as `General registry`, `FileIO` and even GitHub usage...

