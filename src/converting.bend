# { 
    no conversions between datatypes yet? fine, i'll do it myself...
    if it doesnt have a comment next to it saying to use it, its probably
    an internally useful function rather than an outwardly facing thing
    so be careful of using those.
    the ones you'll want to use are:
    u24_to_str
    f24_to_str
    str_to_u24
    str_to_f24
# }

def slice_numeral_f(num: f24) -> f24:
    num2 = (num / 10.0) * 10.0
    slice = num - num2
    return slice

def numerals_to_str_f(num: f24) -> String:
    switch num:
        case 0.0:
            return "0"
        case 1.0:
            return "1"
        case 2.0:
            return "2"
        case 3.0:
            return "3"
        case 4.0:
            return "4"
        case 5.0:
            return "5"
        case 6.0:
            return "6"
        case 7.0:
            return "7"
        case 8.0:
            return "8"
        case 9.0:
            return "9"
        case _:
            return ("" + numerals_to_str_f(num / 10) + numerals_to_str_f(slice_numeral_f(num)))

def slice_numeral_u(num: u24) -> u24:
    num2 = (num / 10) * 10
    slice = num - num2
    return slice

# use this one
def u24_to_str(num: u24) -> String:
    switch num:
        case 0:
            return "0"
        case 1:
            return "1"
        case 2:
            return "2"
        case 3:
            return "3"
        case 4:
            return "4"
        case 5:
            return "5"
        case 6:
            return "6"
        case 7:
            return "7"
        case 8:
            return "8"
        case 9:
            return "9"
        case _:
            return ("" + u24_to_str(num / 10) + u24_to_str(slice_numeral_u(num)))

def slice_decimal(num: f24) -> f24:
    return Math/floor(num * 10.0)

def decimal_to_str(num: f24) -> String:
    if Math/ceil(num):
        num2 = num * 10.0
        num3 = num - num2
        if Math/ceil(num3):
            return ("." + slice_decimal(num) + decimal_to_str(num))
        else:
            return ("." + slice_decimal(num))
    else:
        return ".0"

# use this one too
def f24_to_str(num: f24) -> f24:
    str = ""
    numfloor = Math/floor(num)
    str += numerals_to_str_f(numfloor)
    numdec = num - numfloor
    str += decimal_to_str(numdec)
    return str
            
def char_to_f24(str: String) ->:
    mode = 1.0
    match str:
        case String/Cons:
            match str.head:
                case "0":
                    return 0.0
                case "1":
                    return 1.0
                case "2":
                    return 2.0
                case "3":
                    return 3.0
                case "4":
                    return 4.0
                case "5":
                    return 5.0
                case "6":
                    return 6.0
                case "7":
                    return 7.0
                case "8":
                    return 8.0
                case "9":
                    return 9.0
                case ".":
                    return -1.0
                case _:
                    return 0.0
        case String/Nil:
            return 0.0

def str_to_map(str, count):
    bend count:
        case 0:
            return Map/Leaf
        case _:
            return Map/Node(
                str.head,
                str_to_map(str, count - 1)
                )

def smap_to_f24(smap, count, precision):
    flt = 0.0
    count2 = 0
    switch count2:
        case precision:
        case _:
            slice = smap[count2].value
            if slice >= 0.0:
                flt += slice * (10.0 ** to_f24(count2))
            count2 += 1
    switch count2:
        case remain:
        case _:
            slice = smap[count2].value
            if slice >= 0.0:
                flt += slice * ( 0.1 ** to_f24(count2))
            count2  += 1
    return flt

# this one is also good to use
def str_to_f24(str: String) -> f24:
    count = 0
    match str:
        case String/Cons:
            count += 1
        case String/Nil:
            count += 0
    smap = str_to_map(str, count)
    precision = 0.0
    count2 = 0
    count3 = 0.0
    switch count2:
        case count:
        case _:
            slice = smap[count2].value
            if slice == ".":
                precision = count3
                count2 += 1
            else:
                count2 += 1
    return smap_to_f24(smap, count, precision)
 
# this one is good to use too
def str_to_u24(str: String) -> u24:
    retval = 0
    count = 0
    match str:
        case String/Cons:
            count += 1
        case String/Nil:
            count += 0
    smap = str_to_map(str, count)
    count2 = 0
    switch count2:
        case count:
        case _:
            slice = smap[count2].value
            if slice >= 0:
                retval += slice * to_u24(10.0 ** to_f24(count2))
            count2 += 1
    return retval
