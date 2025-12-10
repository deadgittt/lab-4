-- авто-деривация через GHC.Generics, JsonRead и GJsonRead
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}

module JSON.Generic (
    JsonRead (..), -- класс с parse
) where

import GHC.Generics
import JSON.AST
import JSON.FromJSON
import JSON.Parser

class GJsonRead f where
    gParseJSON :: Json -> Either String (f p)

class JsonRead a where
    parse :: String -> Either String a
    default parse :: (Generic a, GJsonRead (Rep a)) => String -> Either String a
    parse s = do
        json <- parseJson s
        rep <- gParseJSON json
        pure (to rep)

-- Инстансы GJsonRead для U1, K1, M1, (:*:)
-- Плюс вспомогательные функции, например для JObject/record'ов
