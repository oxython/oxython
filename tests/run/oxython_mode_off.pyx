# mode: run
# tag: oxython

#[a .pyx file is plain Cython, so this is an ordinary comment]

def names_stay_free(fn, let, use, loop):
    """
    In .pyx files nothing changes, so the new words are normal names.

    >>> names_stay_free(1, 2, 3, 4)
    10
    """
    return fn + let + use + loop


def slices(seq):
    """
    >>> slices(list(range(6)))
    [0, 2, 4]
    """
    return seq[::2]
