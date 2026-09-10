module Parser.Core (
    Parser (..), -- экспортируем конструктор для самостоятельных парсеров
) where

import Control.Applicative

-- Декартов тип (АТД с одним конструктором)
newtype Parser a = Parser
    { runParser :: String -> Either String (a, String)
    } -- полем является именованное поле `функций runParser`

instance Functor Parser where -- здесь Parser - это конструктор типа
-- (Parser p) -- паттерн мэтчинг для распаковки функции p (runParser)
    fmap f (Parser p) =
        Parser $ \input ->
            case p input of
                Left err -> Left err
                Right (a, rest) -> Right (f a, rest)

instance Applicative Parser where
    -- pure заворачивает значение без потребления входа
    pure a = Parser $ \input -> Right (a, input)

    -- <*> последовательно запускает парсер функции, затем парсер аргумента
    (Parser pf) <*> (Parser pa) =
        Parser $ \input ->
            case pf input of
                Left err -> Left err
                Right (f, rest) ->
                    case pa rest of
                        Left err -> Left err
                        Right (a, rest') -> Right (f a, rest')

instance Monad Parser where
    -- >>= запускает первый парсер и передаёт результат в следующий
    (Parser pa) >>= f =
        Parser $ \input ->
            case pa input of
                Left err -> Left err
                Right (a, rest) ->
                    let Parser pb = f a
                     in pb rest

instance Alternative Parser where
    -- empty всегда проваливается с сообщением
    empty = Parser $ const (Left "empty")

    -- <|> пробует первый парсер, а при ошибке второй
    (Parser p1) <|> (Parser p2) =
        Parser $ \input ->
            case p1 input of
                Left _ -> p2 input
                success -> success
