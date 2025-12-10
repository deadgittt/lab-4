# Лабораторная работа №4
**Выполнил**: Гайдеров Ярослав Игоревич \
**Группа**: Р3431 \
**Преподаватель**: Пенской Александр Владимирович \
**Язык**: Haskell

---

## Высокоуроневое опсиание задания
- сделать либу парсер комбинаторов с автоматической деривиацией (deriving) Json-парсера для кастомного пользовательского типа
- поддержать стандартные числовые типы Int, Float, String
- поддержать Maybe, Either, List (синтаксис json на усмотрение студента)

## Более подробно

### Этап 1. Базовый тип Parser и комбинаторы
**Что реализовать**
- Тип:
```haskell
newtype Parser a = Parser { runParser :: String -> Either String (a, String) }
```
- Экземпляры классов: Functor, Applicative, Alternative, Monad
- Примитивные функции: item, satisfy, char, string, spaces
- Комбинаторы: many, some, optional, (<|>)

**Цель этапа**  
Иметь основу, на которой можно строить любой парсер.

### Этап 2. AST JSON
**Что реализовать**
- Тип:
```haskell
data Json
  = JNull
  | JBool Bool
  | JNumber Double
  | JString String
  | JArray [Json]
  | JObject [(String, Json)]
```
- Экземпляры Show/Eq

**Цель этапа**  
Определить внутреннее представление JSON-значений.

### Этап 3. JSON-парсер (строка → Json)
**Что реализовать**
- Парсеры: null, true, false, число, строка, массив, объект.
- Функция: `parseJSON :: String -> Either String Json`

**Цель этапа**  
Рабочий JSON-парсер на собственной библиотеке.

### Этап 4. Класс FromJSON (Json → Haskell тип)
**Что реализовать**
- Класс:
```haskell
class FromJSON a where 
    fromJSON :: Json -> Either String a
```
- Инстансы: 
  - Int, 
  - Double, 
  - String,
  - Maybe a,
  - Either e a,
  - [a]

**Цель этапа**  
Преобразование Json → конкретные типы.

### Этап 5. Generic-инфраструктура
**Что реализовать**
- `import GHC.Generics`
- Generic-класс (каркас):
```haskell
class GJsonRead f where
    gParseJSON :: Json -> Either String (f p)
```
- Инстансы GJsonRead для: 
  - U1,
  - K1,
  - M1,
  - :*:
- (Можно начать с минимальной поддержки только record-типа.)

**Цель этапа**  
Научиться обходить Generic-представление типа.

### Этап 6. Класс JsonRead (auto-deriving)
**Что реализовать**
- Класс:
```haskell
class JsonRead a where
    parse :: String -> a
    default parse :: (Generic a, GJsonRead (Rep a)) => String -> a
```
- Логика:
  1) `parse` вызывает parseJSON (строка → Json)
  2) затем gParseJSON (Json → Rep a)
  3) затем to :: Rep a -> a
 
`parse s`:
```haskell
parseJSON s -> Json

gParseJSON json -> Rep a

to (Rep a) -> a
```

**Цель этапа**  
Автоматическое deriving JsonRead без ручного instance.

### Этап 7. Пользовательские типы
**Что реализовать**
- Пример:
```haskell
data Point = Point 
    { x :: Float
    , y :: Float
    , z :: Float 
    } deriving (Generic, JsonRead, Show, Eq)
```
- Демонстрация:
```haskell
parse "{"x":1.0, "y":2.0, "z":3.0}" :: Point
```

**Цель этапа**  
Показать работу deriving на пользовательских структурах.

### Этап 8. Документация
**Что описать**
- какие упрощения JSON сделаны;
- какой синтаксис JSON для Maybe/Either/List;
- какие типы поддерживаются auto-deriving.


## Структура проекта
1. Parser.Core -- тип Parser, ядро
2. Parser.Combinators -- универсальные кирпичики для парсинга
3. JSON.AST -- модель JSON (сугубо данные)
4. JSON.Parser -- конкретный парсер JSON -> Json
5. JSON.FromJSON -- трансформация Json -> обычные типы (Int, Maybe, Either, списки)
6. JSON.Generic -- generic-деривация JsonRead для пользовательских типов
7. Main -- демонстрация/CLI/ручные тесты