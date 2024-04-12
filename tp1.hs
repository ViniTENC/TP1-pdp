import Test.HUnit

{-- Tipos --}

import Data.Either
import Data.List
import qualified Data.Type.Bool as o

data Dirección = Norte | Sur | Este | Oeste
  deriving (Eq, Show)
type Posición = (Float, Float)

data Personaje = Personaje Posición String  -- posición inicial, nombre
  | Mueve Personaje Dirección               -- personaje que se mueve, dirección en la que se mueve
  | Muere Personaje                         -- personaje que muere
  deriving (Eq, Show)

data Objeto = Objeto Posición String        -- posición inicial, nombre
  | Tomado Objeto Personaje                 -- objeto que es tomado, personaje que lo tomó
  | EsDestruido Objeto                      -- objeto que es destruido
  deriving (Eq, Show)
type Universo = [Either Personaje Objeto]

{-- Observadores y funciones básicas de los tipos --}

siguiente_posición :: Posición -> Dirección -> Posición
siguiente_posición p Norte = (fst p, snd p + 1)
siguiente_posición p Sur = (fst p, snd p - 1)
siguiente_posición p Este = (fst p + 1, snd p)
siguiente_posición p Oeste = (fst p - 1, snd p)

posición :: Either Personaje Objeto -> Posición
posición (Left p) = posición_personaje p
posición (Right o) = posición_objeto o

posición_objeto :: Objeto -> Posición
posición_objeto = foldObjeto const (const posición_personaje) id

nombre :: Either Personaje Objeto -> String
nombre (Left p) = nombre_personaje p
nombre (Right o) = nombre_objeto o

nombre_personaje :: Personaje -> String
nombre_personaje = foldPersonaje (const id) const id

está_vivo :: Personaje -> Bool
está_vivo = foldPersonaje (const (const True)) (const (const True)) (const False)

fue_destruido :: Objeto -> Bool
fue_destruido = foldObjeto (const (const False)) const (const True)

universo_con :: [Personaje] -> [Objeto] -> [Either Personaje Objeto]
universo_con ps os = map Left ps ++ map Right os

es_un_objeto :: Either Personaje Objeto -> Bool
es_un_objeto (Left o) = False
es_un_objeto (Right p) = True

es_un_personaje :: Either Personaje Objeto -> Bool
es_un_personaje (Left o) = True
es_un_personaje (Right p) = False

-- Asume que es un personaje
personaje_de :: Either Personaje Objeto -> Personaje
personaje_de (Left p) = p

-- Asume que es un objeto
objeto_de :: Either Personaje Objeto -> Objeto
objeto_de (Right o) = o

en_posesión_de :: String -> Objeto -> Bool
en_posesión_de n = foldObjeto (const (const False)) (\ r p -> nombre_personaje p == n) (const False)

objeto_libre :: Objeto -> Bool
objeto_libre = foldObjeto (const (const True)) (const (const False)) (const False)

norma2 :: (Float, Float) -> (Float, Float) -> Float
norma2 p1 p2 = sqrt ((fst p1 - fst p2) ^ 2 + (snd p1 - snd p2) ^ 2)

cantidad_de_objetos :: Universo -> Int
cantidad_de_objetos = length . objetos_en

cantidad_de_personajes :: Universo -> Int
cantidad_de_personajes = length . personajes_en

distancia :: (Either Personaje Objeto) -> (Either Personaje Objeto) -> Float
distancia e1 e2 = norma2 (posición e1) (posición e2)

objetos_libres_en :: Universo -> [Objeto]
objetos_libres_en u = filter objeto_libre (objetos_en u)

está_el_personaje :: String -> Universo -> Bool
está_el_personaje n = foldr (\x r -> es_un_personaje x && nombre x == n && (está_vivo $ personaje_de x) || r) False

está_el_objeto :: String -> Universo -> Bool
está_el_objeto n = foldr (\x r -> es_un_objeto x && nombre x == n && not (fue_destruido $ objeto_de x) || r) False

-- Asume que el personaje está
personaje_de_nombre :: String -> Universo -> Personaje
personaje_de_nombre n u = foldr1 (\x1 x2 -> if nombre_personaje x1 == n then x1 else x2) (personajes_en u)

-- Asume que el objeto está
objeto_de_nombre :: String -> Universo -> Objeto
objeto_de_nombre n u = foldr1 (\x1 x2 -> if nombre_objeto x1 == n then x1 else x2) (objetos_en u)

es_una_gema :: Objeto -> Bool
es_una_gema o = isPrefixOf "Gema de" (nombre_objeto o)

{-Ejercicio 1-}

-- recibe f1, f2 y f3; las funciones que se aplican a cada caso de Personaje
-- f1: Personaje -> a -> a
-- f2: a -> Personaje -> Dirección -> a
-- f3: a -> a
foldPersonaje :: (Personaje -> a -> a) -> (a -> Personaje -> Dirección -> a) -> (a -> a) -> Personaje -> a
foldPersonaje f1 f2 f3 p = case p of
                  Personaje pos str -> f1 p 
                  Mueve p' d -> f2 (rec p') p' d
                  Muere p' -> f3 (rec p')
                  where rec = foldPersonaje f1 f2 f3

foldObjeto :: (Objeto -> a -> a) -> (a -> Personaje -> a) -> (a -> a) -> Objeto -> a
foldObjeto f1 f2 f3 obj = case obj of
                  Objeto pos str -> f1 obj str
                  Tomado obj' p -> f2 (rec obj') p
                  EsDestruido obj' -> f3 (rec obj')
                  where rec = foldObjeto f1 f2 f3

{-Ejercicio 2-}

posición_personaje :: Personaje -> Posición

-- f1 es id porque, si es Personaje, quiero que me devuelva la posición actual
-- f2 es la funcion que se aplica a Mueve. Quiero que sea siguiente_posicion
-- f3 es id porque, si es Muere, quiero que me devuelva la posición actual
posición_personaje = foldPersonaje (\pos str -> pos)
                                    (\p direccion -> siguiente_posición (posición_personaje p) direccion) 
                                    (\p -> p)


nombre_objeto :: Objeto -> String

-- f1 es id porque, si es Objeto, quiero que me devuelva el nombre actual
nombre_objeto = foldObjeto (\o str -> str) 
                          (\obj p -> (\o str -> str) obj)  -- caso objeto tomado
                          (\r -> (\o str -> str) obj)      --caso objeto destruido

-- {-Ejercicio 3-}

objetos_en :: Universo -> [Objeto]
objetos_en = foldr (\x rec -> if es_un_objeto x then objeto_de x : rec else rec) []

-- o.. puede ser mas facil para la demo? nose
--objetosEn [] = []
--objetosEn (x:xs) = if es_un_objeto x then objeto_de x : objetosEn xs
                                      else objetosEn xs
                                    


personajes_en :: Universo -> [Personaje]
personajes_en = foldr (\x rec -> if es_un_personaje x then personaje_de x : rec else rec) []

-- {-Ejercicio 4-}


objetos_en_posesión_de ::  Personaje -> Universo -> [Objeto]
objetos_en_posesión_de p = foldr (\x rec -> if es_un_objeto x && en_posesión_de (nombre_personaje p) x then x : rec
                                                                                                      else rec) []  

-- {-Ejercicio 5-}

-- -- Asume que hay al menos un objeto
-- objeto_libre_mas_cercano :: ?
-- objeto_libre_mas_cercano = ?

-- {-Ejercicio 6-}

-- tiene_thanos_todas_las_gemas :: ?
-- tiene_thanos_todas_las_gemas = ?

-- {-Ejercicio 7-}

-- podemos_ganarle_a_thanos :: ?
-- podemos_ganarle_a_thanos = ?

{-Tests-}

main :: IO Counts
main = do runTestTT allTests

allTests = test [ -- Reemplazar los tests de prueba por tests propios
  "ejercicio1" ~: testsEj1,
  "ejercicio2" ~: testsEj2,
  "ejercicio3" ~: testsEj3,
  "ejercicio4" ~: testsEj4,
  "ejercicio5" ~: testsEj5,
  "ejercicio6" ~: testsEj6,
  "ejercicio7" ~: testsEj7
  ]

phil = Personaje (0,0) "Phil"
mjölnir = Objeto (2,2) "Mjölnir"
universo_sin_thanos = universo_con [phil] [mjölnir]

testsEj1 = test [ -- Casos de test para el ejercicio 1
  foldPersonaje (\p s -> 0) (\r d -> r+1) (\r -> r+1) phil             -- Caso de test 1 - expresión a testear
    ~=? 0                                                               -- Caso de test 1 - resultado esperado
  ,
  foldPersonaje (\p s -> 0) (\r d -> r+1) (\r -> r+1) (Muere phil)     -- Caso de test 2 - expresión a testear
    ~=? 1                                                               -- Caso de test 2 - resultado esperado
  ]

testsEj2 = test [ -- Casos de test para el ejercicio 2
  posición_personaje phil       -- Caso de test 1 - expresión a testear
    ~=? (0,0)                   -- Caso de test 1 - resultado esperado
  ]

testsEj3 = test [ -- Casos de test para el ejercicio 3
  objetos_en []       -- Caso de test 1 - expresión a testear
    ~=? []            -- Caso de test 1 - resultado esperado
  ]

testsEj4 = test [ -- Casos de test para el ejercicio 4
  objetos_en_posesión_de "Phil" []       -- Caso de test 1 - expresión a testear
    ~=? []                             -- Caso de test 1 - resultado esperado
  ]

testsEj5 = test [ -- Casos de test para el ejercicio 5
  objeto_libre_mas_cercano phil [Right mjölnir]       -- Caso de test 1 - expresión a testear
    ~=? mjölnir                                       -- Caso de test 1 - resultado esperado
  ]

testsEj6 = test [ -- Casos de test para el ejercicio 6
  tiene_thanos_todas_las_gemas universo_sin_thanos       -- Caso de test 1 - expresión a testear
    ~=? False                                            -- Caso de test 1 - resultado esperado
  ]

testsEj7 = test [ -- Casos de test para el ejercicio 7
  podemos_ganarle_a_thanos universo_sin_thanos         -- Caso de test 1 - expresión a testear
    ~=? False                                          -- Caso de test 1 - resultado esperado
  ]