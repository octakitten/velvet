# {
#   Our first order of business is to implement a hash function that will
#   allow us to generate pseudo random batches of numbers that can be
#   used in the model's arrays as individual values.

#   the function should be one to one across a certain useful domain
#   that we like, namely it should be one to one across a domain
#   inclusive of the highest possible value for an int24 number, since 
#   thats what we'll be using for parameter values.

#   we'll need to measure this hash function to make sure that it has a decent
#   distribution across our domain, although we're mostly interested in the lower
#   half of the range, rather than the upper half. i dont expect the model will like
#   to use large numbers in its parameters much.

#   we'll also need to use the cryptographic functions of the operating system 
#   to seed the hash table somehow. im thinking that will have to be a 
### command line input to the program, maybe. we'll see

#   so, qualities of our hash function that we need:
#   - an even distribution across the range 0 <= y <= max(int24)
#   (whatever that is) from the domain 0 => max(uint24)
#   - able to be seeded by a random int24 number which will offset its output
#   in a pseudo random fashion while also preserving its other properties
    
#   okay, looks like we can use multiplicative hashing to get what we want here
#   we'll need to write some C code to do this for us and then call the 
#   executable from within bend, but i think we can do that now well enough
#   time to get to work
# }

# import ./hashing.bend

# {
#   back again and ive got the randomizer lib built. debugging will come later because
#   i dont even have a way to test it yet. anyway...
#
#   next order of business is to build the basics of our AI model in bend.
#   this means making lists for each of the layers and layer groups and then
#   making some utility functions like save and load to handle dealing with 
#   the model on a basic level. we'll write the update function later
#
# }

import ./model.bend

# {
#   alright, it took a while but i  managed to create a working definition of a model.
#   thus far it only has an init fuction but we'll add more as we run into a need for them.
#   next up is defining the update function... somehow
#   for this, we're taking a different approach that i think complements bend's strengths well
#   and is the reason ive returned to this strange language.
#
#   we're going to be employing a simple, well-known function, namely arctan(x), as a substitute
#   for all the if-then nonsense we have going on in Silky. arctan(x) is well defined for all 
#   integers on its domain, and its range is easily controlled with parameters we can set
#   programmatically.
#
#   as it so happens, arctan's graph loosely represents what we're trying to achieve.
#   its range extends from -n to +n, and we can choose n. its slope depends on a value we can 
#   easily control as well. all in all it allows us to sort of "flip a switch" in a 
#   way where we don't need to use a discrete function based on boolean statements. instead
#   we rely on the properties of arctan's graph, especially how its output very quickly changes from
#   an approximation of a negative value, goes continuously through the origin, and then hits 
#   an approximation of the same value but positive.
#
#   this allows us to control arctan's graph like so:
#   y = a * arctan(b * x)
#   where a represents the concept of firing values in silky, and b represents the concept of 
#   threshholds. as b increases, the graph starts to look like it dramatically and quickly
#   shifts from approximating -aC to approximating +aC, where C represents the contribution of
#   arctan(b*x). this resembles lowering of the threshhold required of x before the outputs
#   of the function start to approximate +/-aC. the reverse also holds true if b decreases. 
#   
#   similarly, if  increases, the absolute value of +/-aC increases. this can loosely represent
#   an increase in the firing value of the function. since we're using the output of the function 
#   as the firing value, increasing and decresing a works as expected and desired.
#
#   and, of course, at x = 0 the function always flatlines, which is also a desireable trait.
#   in these circumstances we are almost never going to add a constant to x, it would ruin it.
#
#   anyway, this means that the neurons in the first layer of the model will change each other
#   by a value of y = Aarctan(Bx) and we can continue to manipulate A and B in lower layers 
#   of the model. 
#
#   what does THAT mean though? well, in layer 0 we simply define the neurons. when we update 
#   the function, the values in layer0 are shifted and then added together with the value
#   already in place there maybe 6 or so times, or however many times we want, 
#   to represent neurons firing and communicating with each other. then, in the lower layers,
#   the model tree branches, and A is controlled by the same arctan function we used at layer0.
#   then we split the model along branches however many times we want until we have a model
#   we like. at each branch in the model leading to a lower layer, we determine A with one
#   branch and B with the other.
#
#   at the lowest layer we simply set the values of A and B with the randomizer function on 
#   init or by varying preexisting values with another model's parameters.
#   
#   this doesnt cover all the functionality we need though, i think. there still needs to be
#   communication between the layers, not just from lower upwards but also upper layers downwards.
#   so lets see...
#
#   at layer 0, neuron value y0 depends on y0 = Aarctan(Bx), where x is its value in the previous
#   step. it also depends on its neighbor neurons adding to it, which happens after evaluation of
#   the arctan function.
#
#   at layer 1, neuron value y1 = y0 + A * arctan(B * x)
#
#   and then we repeat that for the other layers up until the last layer:
#
#   yn = C
#
#   where C is just a constant determined by our training algorithm or the init function.
#
#   anyway, by evaluating these functions in steps we can transfer information back and forth 
#   between layers, which allows us to store information within the network... indefinitely. it 
#   might change form over time but yea... anyway, lets get to actually defining this function
#   }

DEPTH = 6
WIDTH = 256
MAX = 999
test_vals = ones(WIDTH)
# random_vals = normalize(randomize(WIDTH, MAX), MAX)

model = init_model(test_vals, WIDTH, DEPTH, DEPTH)

# {
#   alright, we've initialized the model.
#   took a couple days to write the utility functions and im not even done.
#   theres a lot of nice little features that you take for granted in programming languages, but,
#   yea, bend doesnt have those
#
#   now its time to boot up this bad boy and start debugging
#   god help me
# }

