module Main (module Main) where

import Rattus
import Rattus.Stream
import Prelude hiding ((<*>))
import Data.Set
import qualified Data.Set as Set


{-# ANN module Rattus #-}

map1 :: Box (a -> b) -> Str a -> Str b
map1 f (x ::: xs) = unbox f x ::: delay (map1 f (adv xs))

map2 :: Box (a -> b) -> Str a -> Str b
map2 f (x ::: xs) = unbox f x ::: (delay map2 <** f <*> xs)

map3 :: Box (a -> b) -> Str a -> Str b
map3 f = run
  where run (x ::: xs) = unbox f x ::: (delay run <*> xs)


-- mutual recursive definition
bar1 :: Box (a -> b) -> Str a -> Str b
bar1 f (x ::: xs) = unbox f x ::: (delay (bar2 f) <*> xs)

bar2 :: Box (a -> b) -> Str a -> Str b
bar2 f  (x ::: xs) = unbox f x ::: (delay (bar1 f) <*> xs)

data Input a = Input {jump :: !a, move :: !Move}
data Move = StartLeft | EndLeft | StartRight | EndRight | NoMove

type Inp a b = Input a



-- The compiler plugin should detect that Input is a stable type and
-- thus remains in scope under the delay.
constS :: Stable a => (Inp a b) -> Str (Inp a b)
constS a = a ::: delay (constS a)

-- The constraint solver plugin should detect that Input is a stable
-- type and thus 'const1' can be instantiated.
constS' :: Stable a => Inp a b -> Str (Inp a b)
constS' = const1

-- make sure that unit is recognized as stable
constU :: () -> Str ()
constU a = a ::: delay (constU a)

constU' :: () -> Str ()
constU' = const1


const1 :: Stable a => a -> Str a
const1 a = a ::: delay (const1 a)

const2 :: Stable a => a -> Str a
const2 a = run
  where run = a ::: delay run

scan1 :: (Stable b) => Box(b -> a -> b) -> b -> Str a -> Str b
scan1 f acc (a ::: as) =  acc' ::: delay (scan1 f acc' (adv as))
  where acc' = unbox f acc a

scan2 :: (Stable b) => Box(b -> a -> b) -> b -> Str a -> Str b
scan2 f = run
  where run acc (a ::: as) = let acc' = unbox f acc a
                             in acc' ::: delay (run acc' (adv as))

scanSet :: Str Int -> Str (Set Int)
scanSet = scan1 (box (\ s x -> Set.insert x s)) Set.empty

from :: Int -> Str Int
from n  = n ::: delay (from (n+1))

alt :: Int -> Int -> Str Int
alt n m = n ::: delay (alt m n)


{-# ANN main NotRattus #-}
main = putStrLn "This file should just type check"
