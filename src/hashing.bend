# { 
    here is how we will import the c and cuda libraries we need for the 
    hashing stuff we need to do in bend
    this was the pain point i had last time i attempted to use Bend for 
    my project, so if we can get this working it'll be a 
    big victory
# }

def randomize(amount: u24, max: f24) -> List(f24):
  with IO:
    hashlib <- IO/DyLib/open("./hashing.so", 0)
    bend amount:
      case 0:
        return List(f24)/Nil
      case _:
        return List(f24)/Cons(
          head <- IO/DyLib/call(hashlib, "hashgrab", 1),
          tail = randomize(amount - 1, max)
          )

        
def normalize(list: List(f24), max: u24) -> Map(f24):
  fold list:
    case List/Cons:
      return Map(f24)/Node(
        list.head % (max + 1.0),
        normalize(list.tail, max),
        Map/Leaf
        )
    case List/Nil:
      return Map(f24)/Leaf
  return list
