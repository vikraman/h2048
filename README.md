# h2048

a haskell implementation of Game 2048

Based on [2048](https://github.com/gabrielecirulli/2048)

# Screenshots

## Simple CLI version

![](https://github.com/Javran/h2048/releases/download/0.1.0.0/h2048-simple.jpg)

## vty CLI version

![](https://github.com/Javran/h2048/releases/download/0.1.0.0/h2048-vty.jpg)

## Build and run

### With cabal

If you have [Cabal](http://www.haskell.org/cabal/) installed,
you can use the following command to build this project:

    cabal build

The executable will be located at `dist/build/h2048-simple/h2048-vty`,
to run the program:

    ./dist/build/h2048-simple/h2048-vty

Or alternatively:

    cabal run h2048-vty

If you have trouble building the `vty` CLI version,
you can try to turn off feature `vty` it and use `h2028-simple`:

    cabal configure --flag="-vty"
    cabal build
    # now the program should be ready
    cabal run h2048-simple
    # or alternatively:
    ./dist/build/h2048-simple/h2048-simple

### Without cabal

First make sure the following dependencies are installed:

* [transformers](http://hackage.haskell.org/package/transformers)
* [mtl](http://hackage.haskell.org/package/mtl)
* [MonadRandom](http://hackage.haskell.org/package/MonadRandom)

In addition, if you want to play with vty CLI version, the following dependencies
are also required:

* [text](http://hackage.haskell.org/package/text)
* [vty](http://hackage.haskell.org/package/vty)
* [vty-ui](http://hackage.haskell.org/package/vty-ui)

You can use following commands to run the program without cabal:

    cd src # assume your working directory is the project home.
    # to play the simple CLI version
    runhaskell MainSimple.hs
    # to play the vty CLI version
    runhaskell MainVty.hs

## How to play

keys:

* `q`: quit
* `i`: up
* `k`: down
* `j`: left
* `l`: right

If you are using `h2048-vty`, you can also use arrow keys.
