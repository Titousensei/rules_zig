from shared import c_add, c_divide, c_hello, c_debug, c_sum

b = c_add(400, 123)
print("* add ", b)

b = c_sum(400, 132)
print("* sum ", b)

c = c_divide(2, 3)
print("* divint", c)

c = c_divide(7.0, 3.5)
print("* divfloat", c)

try:
    d = c_divide(2, 0)
    print("* div0", d)
except ex:
    print("* ex", ex)

c_hello()
c_debug("WoRlD")
