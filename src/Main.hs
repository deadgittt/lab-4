module Main where

import JSON.Parser

main :: IO ()
main = do
    let s = "{\"msg\": \"h e l l o\", \"nums\": [1, 2, 3]}"
    print (parseJson s)
