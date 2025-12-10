-- Задача: преобразование Json -> обычные Haskell-типы
{-# LANGUAGE FlexibleInstances #-}

module JSON.FromJSON (
    FromJSON (..),
) where

import JSON.AST

class FromJSON a where
    fromJSON :: Json -> Either String a

-- Инстанс для Int с проверкой целой части
instance FromJSON Int where
    fromJSON (JNumber n) =
        let i = round n
         in if fromIntegral i == n
                then Right i
                else Left "expected integer number"
    fromJSON _ = Left "expected JNumber for Int"

-- Инстанс для Double
instance FromJSON Double where
    fromJSON (JNumber n) = Right n
    fromJSON _ = Left "expected JNumber for Double"

-- Инстанс для String
instance FromJSON String where
    fromJSON (JString s) = Right s
    fromJSON _ = Left "expected JString for String"

-- Инстанс для Bool
instance FromJSON Bool where
    fromJSON (JBool b) = Right b
    fromJSON _ = Left "expected JBool for Bool"

-- Инстанс для списка, оставляем перекрываемым ради String
instance {-# OVERLAPPABLE #-} (FromJSON a) => FromJSON [a] where
    fromJSON (JArray xs) = traverse fromJSON xs
    fromJSON _ = Left "expected JArray for list"

-- Инстанс для Maybe с трактовкой null как Nothing
instance (FromJSON a) => FromJSON (Maybe a) where
    fromJSON JNull = Right Nothing
    fromJSON v = Just <$> fromJSON v

-- Инстанс для Either, ожидаем объект {"Left": v} или {"Right": v}
instance (FromJSON l, FromJSON r) => FromJSON (Either l r) where
    fromJSON (JObject [("Left", v)]) = Left <$> fromJSON v
    fromJSON (JObject [("Right", v)]) = Right <$> fromJSON v
    fromJSON _ = Left "expected JObject with Left/Right key for Either"
