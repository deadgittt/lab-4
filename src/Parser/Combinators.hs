{-# LANGUAGE LambdaCase #-}
{- HLINT ignore "Use fromMaybe" -}

module Parser.Combinators (
    item,
    satisfy,
    char,
    string,
    spaces,
    eof,
    many1,
    sepBy,
    sepBy1,
    token,
    symbol,
    number,
    between,
    -- и т.д.
) where

import Control.Applicative
import Data.Char
import Parser.Core

-- number :: Parser Int
-- string :: Parser String
-- jsonValue :: Parser Json
-- object :: Parser Json
-- array :: Parser Json

-- Базовый парсер одного символа
item :: Parser Char
item =
    Parser $ \ case
            [] -> Left "unexpected end of input"
            (c : cs) -> Right (c, cs)

-- Парсер символа по предикату
satisfy :: (Char -> Bool) -> Parser Char
satisfy p = do
    c <- item
    if p c
        then pure c
        else Parser $ const (Left ("unexpected char: " ++ [c]))

-- Парсер конкретного символа
char :: Char -> Parser Char
char c = satisfy (== c)

-- Парсер строки как последовательности символов
string :: String -> Parser String
string = traverse char

-- Парсер конца ввода
eof :: Parser ()
eof =
    Parser $ \case
            [] -> Right ((), [])
            _ -> Left "expected end of input"

-- Парсер пробельных символов
spaces :: Parser String
spaces = many (satisfy isSpace)

-- Один или больше повторений парсера
many1 :: Parser a -> Parser [a]
many1 p = (:) <$> p <*> many p

-- Парсер разделённого списка (возможно пустого)
sepBy :: Parser a -> Parser sep -> Parser [a]
sepBy p sep = sepBy1 p sep <|> pure []

-- Парсер разделённого списка (не пустого)
sepBy1 :: Parser a -> Parser sep -> Parser [a]
sepBy1 p sep = (:) <$> p <*> many (sep *> p)

-- Оборачивание парсера с пропуском пробелов вокруг
token :: Parser a -> Parser a
token p = spaces *> p <* spaces

-- Парсер конкретного символа/строки как лексемы
symbol :: String -> Parser String
symbol s = token (string s)

-- Парсер числа с поддержкой знака, дробной и экспоненциальной части
number :: Parser Double
number = token $ do
    sign <- optional (char '-')
    intPart <- some (satisfy isDigit)
    fracPart <- optional (char '.' *> some (satisfy isDigit))
    expPart <-
        optional $
            do
                _ <- char 'e' <|> char 'E'
                signE <- optional (char '+' <|> char '-')
                digits <- some (satisfy isDigit)
                pure $ 'e' : maybe "" (: []) signE ++ digits
    let numStr =
            maybe "" (: []) sign
                ++ intPart
                ++ maybe "" ('.' :) fracPart
                ++ maybe "" id expPart
    pure (read numStr)

-- Парсер, который ограничивает другой парсер открывающим и закрывающим
between :: Parser open -> Parser a -> Parser close -> Parser a
between open p close = open *> p <* close
