-- авто-деривация через GHC.Generics, JsonRead и GJsonRead
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

module JSON.Generic (
    JsonRead (..), -- класс с parse
) where

import GHC.Generics
import JSON.AST
import JSON.FromJSON
import JSON.Parser

-- Класс обхода Generic-представления
class GJsonRead f where
    gParseJSON :: Json -> Either String (f p)

-- Класс для конечных типов
class JsonRead a where
    -- Главная функция парсинга с авто-деривацией
    parse :: String -> Either String a
    default parse :: (Generic a, GJsonRead (Rep a)) => String -> Either String a
    parse s = do
        json <- parseJson s
        rep <- gParseJSON json
        pure (to rep)

-- Пустой конструктор
instance GJsonRead U1 where
    gParseJSON _ = Right U1

-- Константа-поле, опирается на FromJSON
instance (FromJSON a) => GJsonRead (K1 i a) where
    gParseJSON j = K1 <$> fromJSON j

-- Метаинформация о типе
instance (GJsonRead f) => GJsonRead (M1 D c f) where
    gParseJSON j = M1 <$> gParseJSON j

-- Метаинформация о конструкторе
instance (GJsonRead f) => GJsonRead (M1 C c f) where
    gParseJSON j = M1 <$> gParseJSON j

-- Метаинформация о селекторе (поле записи)
instance (Selector s, GJsonRead f) => GJsonRead (M1 S s f) where
    gParseJSON :: forall p. Json -> Either String (M1 S s f p)
    gParseJSON (JObject fields) = do
        -- достаём имя поля записи через метаданные селектора
        let name = selName (undefined :: M1 S s f p)
        case name of
            "" -> Left "expected record selector name"
            _ -> case lookup name fields of
                Just v -> M1 <$> gParseJSON v
                Nothing -> Left ("missing field: " ++ name)
    gParseJSON _ = Left "expected object for record field"

-- Декартово произведение (поля записи)
instance (GJsonRead f, GJsonRead g) => GJsonRead (f :*: g) where
    gParseJSON j = (:*:) <$> gParseJSON j <*> gParseJSON j

-- Общий инстанс FromJSON для любого Generic-типа с поддержкой GJsonRead
instance {-# OVERLAPPABLE #-} (Generic a, GJsonRead (Rep a)) => FromJSON a where
    fromJSON j = to <$> gParseJSON j
