import ./file_ops.bend
import ./converting.bend

# datastructure that contains all our models parameters.
# when you create one of these, you will need to keep track of its "Depth" property
# in the top level. its not stored anywhere in the model itself, but still needed
# to do things like save the model to disk
type Model(T):
  Root { ~at: Layer(T), ~left: Model(T), ~right: Model(T) }
  Node { ~at: Layer(T), ~left: Model(T), ~right: Model(T) }
  Leaf { ~at: Layer(T) }

type Layer(T):
  Node { value: T, ~next: Layer(T) }
  Leaf { value: T }

# you know i honestly dont know what this is for
def identity(x):
  return x

# inits a LAYER to be all zeros.
# does NOT init a model
def zeros(num_vals: u24) -> Layer(i24):
  switch num_vals:
    case 0:
      return Layer(i24)/Leaf(
        +0
        )
    case _:
      return Layer(i24)/Node(
        +0,
        zeros(num_vals - 1)
        )

# inits a LAYER to be all ones.
# does NOT init a model.
def ones(num_vals: u24) -> Layer(i24):
  switch num_vals:
    case 0:
      return Layer(i24)/Leaf(
        +1
        )
    case _:
      return Layer(i24)/Node(
        +1,
        ones(num_vals - 1)
        )


# used during the init_model function to create layers of neurons
# dont need to use it if you're just initializing a model.
def init_layer(vals: Layer(i24), num_vals: u24) -> Layer(i24):
  switch num_vals:
    case 0:
      return Layer(i24)/Leaf(
        vals[num_vals]
        )
    case _:
      return Layer(i24)/Node(
        vals[num_vals],
        init_layer(vals, num_vals - 1)
      )

# bend doesnt define arrays, but it does "generate" lists and objects
# this is the function you'll use to actually create a model with specific params.
# i'll probably make a wrapper function at some point though
def init_model(vals: Layer(i24), num_vals: u24, steps: u24, max: u24) -> Model(i24):
  switch steps:
    case 0:
      return Model(i24)/Leaf(
        init_layer(vals, num_vals, type)
        )
    case _:
      if steps == max:
        return Model(i24)/Root(
          ones(num_vals),
          init_model(vals, num_vals, steps - 1, max),
          init_model(vals, num_vals, steps - 1, max)
          )
      else:
        return Model(i24)/Node(
          ones(num_vals),
          init_model(vals, num_vals, steps - 1, max),
          init_model(vals, num_vals, steps - 1, max)
          )

# do you want the neurons to talk to lots of other neurons? make this higher
# having problems with performance? make this lower
SHIFT_STEPS = 6

# this is a silly little function im using to ensure that each layer saves to a unique
# layer file on the disk when im saving the model
# its representative of x**!n
def powseries(exp: u24) -> u24:
  retval = 0.0
  return (powseries_helper(exp, retval))

def powseries_helper(exp: u24, retval:u24) -> u24:
  switch count:
    case 0:
      retval += 1.0
      return to_u24(retval)
    case _:
      retval += 2.0 ** to_f24(exp)
      count -= 1
      return powseries_helper(exp, count)

# the mathematical representation of a neuron firing
# its values depend on the state of other neurons in subsequent layers
#def arctan(a: f24, b: f24, x: f24) -> f24:
#  return (a * Math/atan(b * x))

def plus(a: i24, b:i24) -> i24:
  return (a + b)

def conditional_plus(a: i24, b: i24, c: i24) -> i24:
  if a > c:
    return (a + b)
  elif a < c:
    return (a - b)
  else:
    return (a)

#def accumulate(model1: Model(i24), model2: Model(i24), model3: Model(i24)) -> Layer(i24):
#  match model1:
#    case Model/Root:
#      model1.at = conditional_plus(model1.at, model2.at, model3.at, model1.at)
#      model1.left = accumulate(model1.left, model2.left)
#      model1.right = accumulate(model1.right, model2.right)
#      return model1
#    case Model/Node:
#      model1.at = plus(model1.at, model2.at, model1.at)
#      model1.left = accumulate(model1.left, model2.left)
#      model1.right = accumulate(model1.right, model2.right)
#      return model1
#    case Model/Leaf:
#      model1.at = plus(model1.at, model2.at, model1.at)
#      return model1


# used in the update function
# this is what allows the functions in the root neuron layer to talk to each other
def layer_shift(layer: Layer(i24), steps: u24) -> Layer(i24):
  prev_val = layer.value
  layer.value = layer_shift_helper2(layer)
  return layer_shift_helper(layer, prev_val, steps)

def layer_shift_helper(current: Layer(i24), prev_val: i24, steps: u24) -> Layer(i24):
  switch steps:
    case 0:
      current.value = prev_val
      return current
    case _:
      dummy = current.value
      current.value = prev_val
      prev_val = dummy
      steps -= 1
      return layer_shift_helper(current, prev_val, steps)

def layer_shift_helper2(current: Layer(i24)) -> i24:
  match current:
    case Layer/Leaf:
      return current.value
    case Layer/Node:
      return layer_shift_helper2(current.next)
    case _:
      return +0
  

# {
#    it doesnt look like much, but this is where the magic happens, babyyyyy
#    it really does look kinda simple, especially compared to the hundreds of lines i used in the
#    definition of this function in the Silky project.
#
#    anyway, you just have to run this function when you want the model to do something.
#    that is, after you fed it an input image or file.
#    we'll figure out an output layer eventually.
# }

def update(model: Model(i24), upper: Model(i24)) -> Model(i24):
  match model:
    case Model/Root:
      model.at = plus(model.left.at, model.right.at, model.at)
      return model
    case Model/Node:
      upper.at = conditional_plus(model.at, upper.at, model.left.at)
      upper.at = conditional_plus(model.at, upper.at, model.right.at)
      model.left = update(model.left, model.at)
      model.right = update(model.right, model.at)
      return model
    case Model/Leaf:
      upper.at = upper.at + model.at
      return model

# this function here is used to arrange the layers into usable places so that we can save them to the disk more easily
# eventually we'll have to find a way of actually loading after we've saved but we'll burn that bridge when we get there
def gen_mdl_dir(model: Model(i24), path: String, depth: u24, count: u24):
  with IO:
    match model:
      case Model/Root:
        check = gen_layer_file(model.at, path, count)
        path += u24_to_str(count)
        count += 1
        check = gen_mdl_dir(model.left, path, depth - 1, count)
        path += u24_to_str(count)
        count += 1 + powseries(depth)
        check = gen_mdl_dir(model.right, path, depth - 1, count)
      case Model/Node:
        check = gen_layer_file(model.at, path)
        path += u24_to_str(count)
        count += 1
        check = gen_mdl_dir(model.left, path, depth - 1, count)
        path += u24_to_str(count)
        count += 1 + powseries(depth)
        check = gen_mdl_dir(model.right, path, depth - 1, count)
      case Model/Leaf:
        check = gen_layer_file(model.at, path)
    return True

# here we actually save the layer file to disk
# its important that we save it with a unique name otherwise itll overwrite a file we just saved or do something even worse
# we handle naming of layers in the gen_mdl_dir() function though
def gen_layer_file(layer: Layer(i24), path: String, index: u24):
  with IO:
    fdesc = IO/FS/open(path, "w")
    if layer == Layer/Node:
      index += 1
      let {check = IO/FS/write(path, i24_to_str(layer.value))}
      check = IO/FS/seek(path, index, IO/FS/SEEK_SET)
      check = gen_layer_file(layer.next, path, index)
    elif layer == Layer/Leaf:
      index += 1
      check = IO/FS/write(path, i24_to_str(layer.value))
      check = 0
    else:
      check = 0
    check = IO/FS/close(fdesc)
    return 0

def get_by_index(layer: Layer(i24), index: u24) -> i24:
  switch index:
    case 0:
      return layer.value
    case _:
      match layer:
        case Layer/Node:
          return get_by_index(layer.next, index - 1)
        case Layer/Leaf:
          return layer.value

# create a directory to save the model to, then save it to it. shrimple as dat.
# only works on linux though.
# you did keep track of your model's depth in the top level of your program...
# right?
def save(model: Model(i24), name: String, depth: u24):
  with IO:
    path = "models/" + name + ".vlt"
    port = open_bash()
    command = "mkdir -p " + path
    response = bash(port, command)
    check = close_bash(port)
    check = gen_mdl_dir(model, path, depth, 0)
    return True
