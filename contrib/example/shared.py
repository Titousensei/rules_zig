# This should be a generated file

from ctypes import CDLL, c_int, c_float, c_char_p

# TODO: how to pass this path?
_c = CDLL("examples/libshared_zig.so")

# Move this function in a util and import here
def wrap_fn(func, restype, *argtypes):
    func.restype = restype
    func.argtypes = list(argtypes)
    if c_char_p in argtypes:
        def fn(*args):
            fargs = []
            for a, t in zip(args, argtypes):
                if t == c_char_p:
                    fargs.append(str.encode(a))
                else:
                    fargs.append(a)
            func(*fargs)
        return fn
    else:
        return func

# TODO: generate from zig compilation: func names, ret_value type, params types
c_add = wrap_fn(_c.add, c_int, c_int, c_int)
c_sum = wrap_fn(_c.sum, c_float, c_float, c_float)
c_divide = wrap_fn(_c.divide, c_float, c_float, c_float)
c_hello = wrap_fn(_c.hello, None)
c_debug = wrap_fn(_c.debug, None, c_char_p)
