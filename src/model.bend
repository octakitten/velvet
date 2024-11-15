# import ./file_ops.bend
import ./converting.bend

# datastructure that contains all our models parameters.
# when you create one of these, you will need to keep track of its "Depth" property 
# in the top level. its not stored anywhere in the model itself, but still needed
# to do things like save the model to disk
type Model(T):
    Root { ~at: Map(T), ~left: Model(T), ~right: Model(T) }
    Node { ~at: Map(T), ~left: Model(T), ~right: Model(T) }
    Leaf { ~at: Map(T) }

# you know i honestly dont know what this is for
def identity(x):
    return x
    
# inits a LAYER to be all zeros.
# does NOT init a model
def zeros(num_vals: u24) -> Map(f24):
    switch num_vals:
        case 0:
            return Map(f24)/Leaf
        case _:
            return Map(f24)/Node(
                0.0,
                zeros(num_vals - 1)

# inits a LAYER to be all ones.
# does NOT init a model. 
def ones(num_vals: u24) -> Map(f24):
    switch num_vals:
        case 0:
            return Map(f24)/Leaf
        case _:
            return Map(f24)/Neuron(
                1.0,
                ones(num_vals - 1)


# used during the init_model function to create layers of neurons
# dont need to use it if you're just initializing a model.
def init_layer(vals: Map(f24), num_vals: u24) -> Map(f24):
    switch num_vals:
        case 0:
            return Map(f24)/Leaf
        case _:
            return Map(f24)/Node(
                vals[num_vals],
                init_layer(vals, num_vals - 1)
            )

# bend doesnt define arrays, but it does "generate" lists and objects
# this is the function you'll use to actually create a model with specific params.
# i'll probably make a wrapper function at some point though
def init_model(vals: Map(f24), num_vals: u24, steps: u24, max: u24) -> Model(f24): 
    switch steps:
        case max:
            model = Model(f24)/Root(
                ones(num_vals),
                init_model(vals, num_vals, steps - 1, max),
                init_model(vals, num_vals, steps - 1, max)
                )
        case 0:
            model = Model(f24)/Leaf(
                model.at = init_layer(vals, num_vals, type) 
                )
            return model
        case _:
            model = Model(f24)/Node(
                ones(num_vals),
                init_model(vals, num_vals, steps - 1, max),
                init_model(vals, num_vals, steps - 1, max)
                )
            return model

# do you want the neurons to talk to lots of other neurons? make this higher
# having problems with performance? make this lower
SHIFT_STEPS = 6

# this is a silly little function im using to ensure that each layer saves to a unique
# layer file on the disk when im saving the model
# its representative of x**!n
def powseries(exp: u24) -> u24:
    retval = 0.0
    switch exp:
        case _:
            retval += 2.0 ** to_f24(exp)
            exp -= 1
        case 0:
            retval += 1.0
    return to_u24(retval)

# the mathematical representation of a neuron firing
# its values depend on the state of other neurons in subsequent layers
def arctan(a: f24, b: f24, x: f24) -> f24:
    return (a * Math/atan(b * x))

# used in the update function 
# this is what allows the functions in the root neuron layer to talk to each other
def layer_shift(layer: Map(f24), steps: u24) -> Map(f24):
    match layer:
        case Map/Node:
            switch steps:
                case 0:
                    layer.val = layer.val + layer.next.val
                case _:
                    layer.val = layer.val + layer.next.val
                    layer_shift(layer.next, steps - 1)
        case Map/Leaf:
    return layer

# {
    it doesnt look like much, but this is where the magic happens, babyyyyy
    it really does look kinda simple, especially compared to the hundreds of lines i used in the 
    definition of this function in the Silky project.

    anyway, you just have to run this function when you want the model to do something.
    that is, after you fed it an input image or file.
    we'll figure out an output layer eventually.
# }
def update(model: Model(f24), upper: Model(f24)) -> Model(f24):
    match model:
        case Model/Root:
            model.at = arctan(model.left.at, model.right.at, model.at)
            model.at = layer_shift(model.at, SHIFT_STEPS)
        case Model/Node:
            model.at = arctan(model.left.at, model.right.at, model.at)
            upper.at = upper.at + model.at
            update(model.left, model.at)
            update(model.right, model.at)
        case Model/Leaf:
            upper.at = upper.at + model.at
    return model
                
# this function here is used to arrange the layers into usable places so that we can save them to the disk more easily
# eventually we'll have to find a way of actually loading after we've saved but we'll burn that bridge when we get there
def gen_mdl_dir(model: Model(f24), path String, depth: u24, count: u24):
    with IO:
        match model:
            case Model/Root:
                gen_layer_file(model.at, path)
                path += u24_to_str(count)
                count += 1
                gen_mdl_dir(model.left, path, depth - 1, count)
                path += u24_to_str(count)
                count += 1 + powseries(depth)
                gen_mdl_dir(model.right, path, depth - 1, count)
            case Model/Node:
                gen_layer_file(model.at, path)
                path += u24_to_str(count)
                count += 1
                gen_mdl_dir(model.left, path, depth - 1, count)
                path += u24_to_str(count)
                count += 1 + powseries(depth)
                gen_mdl_dir(model.right, path, depth - 1, count)
            case Model/Leaf:
                gen_layer_file(model.at, path)
        return

# here we actually save the layer file to disk 
# its important that we save it with a unique name otherwise itll overwrite a file we just saved or do something even worse
# we handle naming of layers in the gen_mdl_dir() function though
def gen_layer_file(layer: Map(f24), path: String):
    with IO:
        fdesc = IO/FS/open(path, "w")
        index = 0
        switch index:
            case 0:
                IO/FS/write(path, layer[index].value)
            case _:
                val = layer[index]
                match val:
                    case Map/Node:
                        IO/FS/seek(path, index, IO/FS/SEEK_SET)
                        IO/FS/write(path, val.value)
                    case Map/Leaf:
        IO/FS/close(fdesc)
        return

# create a directory to save the model to, then save it to it. shrimple as dat.
# only works on linux though.
# you did keep track of your model's depth in the top level of your program...
# right?
def save(model: Model(f24), name: String, depth: u24):
    with IO:
        path = "models/" + name + ".vlt"
        port = open_bash()
        command = "mkdir -p " + path
        response = bash(port, command)
        close_bash(port)

        gen_mdl_dir(model, path, depth, 0)
        return
