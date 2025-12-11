{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}

module Main (main) where

import GHC.Generics (Generic)
import JSON.AST
import JSON.FromJSON
import JSON.Generic
import JSON.Parser

-- Проверка равенства с сообщением
assertEqual :: (Eq a, Show a) => String -> a -> a -> IO ()
assertEqual label expected actual =
    if expected == actual
        then pure ()
        else error (label ++ ": expected " ++ show expected ++ ", got " ++ show actual)

-- Распаковка Right или падение с ошибкой
expectRight :: String -> Either String a -> a
expectRight label =
    either (\err -> error (label ++ ": " ++ err)) id

-- Тип для проверки авто-деривации
data Point = Point
    { x :: Float
    , y :: Float
    , z :: Float
    }
    deriving (Show, Eq, Generic, JsonRead)

data Sutdent = Student
    { name :: String
    , lastname :: String
    , age :: Int
    , university :: String
    , work :: Maybe String
    , location :: Maybe Point
    }
    deriving (Show, Eq, Generic, JsonRead)

main :: IO ()
main = do
    -- Тест: парсинг объекта с числом
    let obj = expectRight "parse object" (parseJson "{\"a\": 1}")
    assertEqual "object ast" (JObject [("a", JNumber 1)]) obj

    -- Тест: парсинг массива со смешанными типами
    let arr = expectRight "parse array" (parseJson "[true, null, \"hi\"]")
    assertEqual
        "array ast"
        (JArray [JBool True, JNull, JString "hi"])
        arr

    -- Тест: экранированная кавычка в строке
    let strVal = expectRight "parse string" (parseJson "\"quote: \\\"\"")
    assertEqual "string ast" (JString "quote: \"") strVal

    -- Тест: fromJSON списка Int
    let listJson = expectRight "parse number list" (parseJson "[1, 2, 3]")
    let ints = expectRight "fromJSON [Int]" (fromJSON listJson :: Either String [Int])
    assertEqual "list values" [1, 2, 3] ints

    -- Тест: fromJSON Maybe с null
    let nullJson = expectRight "parse null" (parseJson "null")
    let maybeVal = expectRight "fromJSON Maybe" (fromJSON nullJson :: Either String (Maybe Int))
    assertEqual "maybe value" Nothing maybeVal

    -- Тест: fromJSON Either через объект с ключом Left
    let eitherJson = expectRight "parse either" (parseJson "{\"Left\": \"oops\"}")
    let eVal = expectRight "fromJSON Either" (fromJSON eitherJson :: Either String (Either String Int))
    assertEqual "either value" (Left "oops") eVal

    -- Тесты: авто-деривация JsonRead через Generic
    -- Point test
    let pointVal = expectRight "generic parse" (parse "{\"x\":1.0,\"y\":2.0,\"z\":1.5}" :: Either String Point)
    assertEqual "point value" (Point 1.0 2.0 1.5) pointVal
    print pointVal

    -- Student test
    let studentVal = expectRight "generic parse" (parse "{\"name\":\"Yaroslav\",\"lastname\":\"Gaiderov\",\"age\":21, \"university\":\"ITMO\", \"work\":\"Syntacore\", \"location\": {\"x\":1.0, \"y\":2.0, \"z\":3.0}}" :: Either String Student)
    assertEqual "student value" (Student "Yaroslav" "Gaiderov" 21 "ITMO" (Just "Syntacore") (Just (Point 1.0 2.0 3.0))) studentVal
    print studentVal

    -- Student test: work = null
    let studentVal2 = expectRight "generic parse null work" (parse "{\"name\":\"Ne\",\"lastname\":\"Yaroslav\",\"age\":18, \"university\":\"ITMO\", \"work\":null, \"location\": null}" :: Either String Student)
    assertEqual "student value null work" (Student "Ne" "Yaroslav" 18 "ITMO" Nothing Nothing) studentVal2
    print studentVal2

    putStrLn "All tests passed!"
