{-# LANGUAGE DeriveGeneric #-}

-- Минимальное демо: парсинг JSON и auto-деривация через Generic
module Main where

import GHC.Generics (Generic)
import JSON.Generic
import JSON.Parser

-- Пользовательский тип для демонстрации авто-деривации
data Point = Point
    { x :: Float
    , y :: Float
    , z :: Float
    }
    deriving (Show, Eq, Generic)

-- Авто-деривация JsonRead через Generic
instance JsonRead Point

main :: IO ()
main = do
    -- Пример строки JSON -> AST
    let s = "{\"msg\": \"h e l l o\", \"nums\": [1, 2, 3]}"
    print (parseJson s)
    -- Пример auto-deriving для Point
    let p = "{\"x\": 1.0, \"y\": 2.0, \"z\": 3.0}"
    print (parse p :: Either String Point)
