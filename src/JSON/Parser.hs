-- парсер JSON, который строит Json

module JSON.Parser (
    parseJson, -- String -> Either String Json
) where

import Control.Applicative
import JSON.AST
import Parser.Combinators
import Parser.Core

-- Парсер литерала null
pNull :: Parser Json
pNull = JNull <$ symbol "null"

-- Парсер булевых литералов
pBool :: Parser Json
pBool = (JBool True <$ symbol "true") <|> (JBool False <$ symbol "false")

-- Парсер чисел как JNumber
pNumber :: Parser Json
pNumber = JNumber <$> number

-- Парсер escape-последовательностей в строке
escapeChar :: Parser Char
escapeChar = do
    _ <- char '\\'
    c <- item
    case c of
        '"' -> pure '"'
        '\\' -> pure '\\'
        '/' -> pure '/'
        'b' -> pure '\b'
        'f' -> pure '\f'
        'n' -> pure '\n'
        'r' -> pure '\r'
        't' -> pure '\t'
        _ -> Parser $ const (Left ("invalid escape: \\" ++ [c]))

-- Парсер символа строки без кавычек и обратного слеша
stringChar :: Parser Char
stringChar = escapeChar <|> satisfy (\c -> c /= '"' && c /= '\\')

-- Парсер строкового литерала JSON
stringLiteral :: Parser String
stringLiteral = token (char '"' *> many stringChar <* char '"')

-- Парсер строки как Json
pString :: Parser Json
pString = JString <$> stringLiteral

-- Парсер массива JSON
pArray :: Parser Json
pArray = do
    -- массив описан как [v1, v2, ...]
    values <- between (symbol "[") (sepBy jsonValue (symbol ",")) (symbol "]")
    pure (JArray values)

-- Парсер пары ключ-значение в объекте
pPair :: Parser (String, Json)
pPair = do
    key <- stringLiteral
    _ <- symbol ":"
    value <- jsonValue
    pure (key, value)

-- Парсер объекта JSON
pObject :: Parser Json
pObject = do
    -- объект описан как {"k": v, ...}
    pairs <- between (symbol "{") (sepBy pPair (symbol ",")) (symbol "}")
    pure (JObject pairs)

-- Парсер любого JSON-значения
jsonValue :: Parser Json
jsonValue = pNull <|> pBool <|> pNumber <|> pString <|> pArray <|> pObject

-- Точка входа: оборачиваем запуск парсера с пропуском пробелов и проверкой конца ввода
parseJson :: String -> Either String Json
parseJson s =
    case runParser (spaces *> jsonValue <* eof) s of
        Left err -> Left err
        Right (value, _) -> Right value
