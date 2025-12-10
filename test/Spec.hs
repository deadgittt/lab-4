module Main (main) where

import JSON.AST
import JSON.FromJSON
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

    putStrLn "All tests passed!"
