-- Задача: описать структуру JSON как AST-типа

module JSON.AST (
    Json (..),
) where

data Json
    = JNull
    | JBool Bool
    | JNumber Double
    | JString String
    | JArray [Json]
    | JObject [(String, Json)]
    deriving (Eq, Show)
