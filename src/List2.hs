module List2 (stripw, intmean, replace) where
import Prelude hiding (foldr, foldl, foldr1, foldl1)
import Data.Char
import Data.Foldable

stripw :: String -> String
stripw = dropWhileRev isSpace . dropWhile isSpace

dropWhileRev :: (a -> Bool) -> [a] -> [a]
dropWhileRev p = foldr (\x xs -> if p x && null xs then [] else x:xs) []

intmean :: (Integral i, Foldable f) => f i -> i
intmean l = if len == 0 then 0 else lsum `div` len where
	(len, lsum) = foldl' (\(!n, !s) elm -> (n+1, s+elm)) (0, 0) l

replace :: (a -> Bool) -> a -> [a] -> [a]
replace f y (x:xs)
	| f x		= y : xs
	| otherwise	= x : replace f y xs
replace _ _ []		= []
