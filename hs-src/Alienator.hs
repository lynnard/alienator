{-# LANGUAGE ForeignFunctionInterface #-}
module Alienator
    ( runAlienator
    )
  where

import qualified Alienator.Main as A

runAlienator :: IO ()
runAlienator = A.main

foreign export ccall runAlienator :: IO ()
