import Foreign
import Foreign.C.Types
import Foreign.C
import Foreign.C.String
import Foreign.Ptr
import Foreign.Storable
import Data.List
import Data.List.Split
import Data.Maybe
import System.Environment
import Debug.Trace

foreign import ccall "matacc.h trans_count"
	trans_count :: CInt

foreign import ccall "matacc.h guard_count"
	guard_count :: CInt

foreign import ccall "matacc.h dna_val"
	c_dna_val :: TableFunc

foreign import ccall "matacc.h nes_val"
	c_nes_val :: TableFunc

foreign import ccall "matacc.h nds_val"
	c_nds_val :: TableFunc

foreign import ccall "matacc.h coen_val"
	c_coen_val :: TableFunc

foreign import ccall "matacc.h get_global_count"
	c_glob_count :: CInt

foreign import ccall "matacc.h init"
	c_init :: CString -> CInt

foreign export ccall to_fann :: CString -> IO(Ptr Float)

type Coordinate = (Int, Int)
type Cluster = (Bool, [Coordinate])
type Table = [[Bool]]
type TableFunc =  CInt -> CInt -> CInt

trace_native :: String -> TableFunc -> CInt -> CInt -> CInt
trace_native n f x y = f (traceShow  (n ++ show (x,y))  x) y

to_c :: Int -> CInt
to_c = fromIntegral . toInteger

from_c :: CInt -> Int
from_c = fromInteger . toInteger

to_c_d :: Double -> CDouble
to_c_d = fromRational . toRational

from_c_d :: CDouble -> Double
from_c_d = fromRational . toRational

mat_val :: TableFunc -> Coordinate -> Bool
mat_val tab (i, j) = (from_c $ tab (to_c i) (to_c j)) == 1

(!!!) :: [[a]] -> Coordinate -> a
xs !!! (i, j) = (xs !! i) !! j

get_table :: String -> Table
get_table s = [[ mat_val f (i, j)| j <- [0..nj-1]] | i <- [0..ni-1]]
	where
		f = table_by_name s
		(ni, nj) = truesize s

count :: Table -> Int
count mat = sum [length $ filter (\x -> x)  row | row <- mat]

size :: Table -> Int
size = (^2) . length

truesize :: String -> Coordinate
truesize s | s == "dna" = (t, t)
		      | s == "coen" = (g, g)
		      | otherwise = (g, t)
			where
				t = from_c trans_count
			        g = from_c guard_count

truesize_tab :: Table -> Coordinate
truesize_tab tab | tab == get_table "dna" = (t, t)
				     | tab == get_table "coen" = (g, g)
				     | otherwise = (g, t)
			where
				t = from_c trans_count
			        g = from_c guard_count

true_frac :: Table -> Float
true_frac t =  (fromIntegral $ count t) / (fromIntegral $ size t)

find_clusters :: Table -> [Cluster]
find_clusters mat = find_clusters' mat [] (0, 0) s
	where
		s | mat == (get_table "dna") = (from_c trans_count, from_c trans_count)
		   | otherwise = (from_c guard_count, from_c trans_count)

find_clusters' :: Table -> [Cluster] -> Coordinate -> Coordinate -> [Cluster]
find_clusters' mat clusters (i, j) s  | j == (snd s) && i == (fst s) - 1 = clusters		     			--done
							    	          | j == (snd s) = find_clusters' mat clusters (i + 1, 0) s		--next row
				    				          | otherwise = find_clusters' mat new_clusters (i, j + 1) s	--next col
									where
					  					new_clusters = clusterize mat clusters (i, j) s
					  					  

clusterize :: Table -> [Cluster] -> Coordinate -> Coordinate -> [Cluster]
clusterize mat clusters coor@(i, j) s = if not $ range_check mat coor then [] else if not $ mat !!! coor then new_clusters else clusters
	where
	  results_m = [find_cluster mat clusters (i + a, j + b) s | a <- [-1, 0, 1], b <- [-1, 0, 1], a /= 0 || b /= 0]
	  results = map isJust results_m
	  found_cluster = any (==True) results
	  mod_cluster@(mod_val, coors) | found_cluster = fromJust $ snd $ head $ filter fst $ zip results results_m
	  	      		       | otherwise = (False, [])
	  new_clusters | found_cluster = (mod_val, (i,j):coors):(clusters \\ [mod_cluster])
		       			| not $ range_check mat coor = clusters
					| otherwise = ((mat !!! coor), [(i, j)]):clusters

range_check :: Table -> Coordinate -> Bool
range_check mat (i, j) | length mat >= i = False
						| i > 0 && length (mat!!j) >= j = False
						| otherwise = True

find_cluster ::Table -> [Cluster] -> Coordinate -> Coordinate -> Maybe Cluster
find_cluster mat clusters coor s | not $ in_range mat coor s = Nothing
			   | filtered == [] = Nothing
		           | otherwise = Just (head filtered)
			   where
				val | range_check mat coor = mat !!! coor
					| otherwise = error "Range Check 2 Failed"
				filtered = filter (\(v, coors) -> (val == v) && (elem coor coors)) clusters

in_range :: Table -> Coordinate -> Coordinate -> Bool
in_range mat (i, j) s | i < 0    || j < 0    = False
		    | i >= (fst s) || j >= (snd s) = False
		    | otherwise            = True
		    where
		     s = truesize_tab mat

pretty_print_table :: String -> (Coordinate -> String) -> IO ()
pretty_print_table tab f = mapM_ putStrLn $ [concat r | r <- t]
	where
		max_idx = (length $ get_table tab) - 1
		t = map (map f) $ [[(i, j) | j <- [0..max_idx]] | i <- [0..max_idx]]

pretty_print_table_XO :: String -> IO()
pretty_print_table_XO tab = pretty_print_table tab (\v -> if mat_val t v then "X" else "O")
	where
		t = table_by_name tab

pretty_print_table_10 :: String -> IO()
pretty_print_table_10 tab = pretty_print_table tab (\v -> if mat_val t v then "1" else "0")
	where
		t = table_by_name tab

pretty_print_table_clusters :: String -> [Cluster] -> IO ()
pretty_print_table_clusters mat clusters = pretty_print_table mat f
    where
	pure_clusters = map (\(_, c) -> c) clusters
	get_cluster coor = find_cluster (get_table mat) clusters coor $ truesize mat
	get_idx coor | isJust c = elemIndex (snd (fromJust c)) pure_clusters
		     | otherwise = Just (-1)
			where
			  c = get_cluster coor

	nr coor | isJust idx = show $ (fromJust idx) + 1
  		| otherwise = show 0
		where
		  idx = get_idx coor
	spaces = cycle [' ']
	f coor = (nr coor) ++ (take (3-(length $ nr coor)) spaces)

table_by_name :: String -> TableFunc
table_by_name n = case n of
	"dna" -> c_dna_val
	"nes" -> c_nes_val
	"nds" -> c_nds_val
	"coen" -> c_coen_val


initFile :: String -> IO Bool
initFile path = res
	where
		res = do
			io <- newCString path
			let status = c_init io
			let r | status == 0 = True
			          | otherwise   = error $ "Error status returned: " ++ show status
			return (status == 0)

is_dve2C :: String -> Bool
is_dve2C = isSuffixOf ".dve2C"

show_clusters :: String -> String
show_clusters name = (show $ length trueclusters) ++ "," ++ (intercalate "," $ map (\(_,vals) -> show $ length vals) trueclusters)
	where
		table = get_table name
		clusters = find_clusters table
		trueclusters = filter (not . fst) clusters

to_csv :: String -> String -> IO ()
to_csv res file = do
	stat <- initFile file
	let go_on = stat || (traceShow  ("File not found: " ++ file) False)
	
	--putStrLn $ file ++ ":" ++ show go_on
	appendFile res $ seq go_on $ file ++ "\n"
	let all_tables = ["dna", "nes", "nds", "coen"]
	let out = concat $ map (\t -> t ++ "=" ++ (show $ true_frac $ get_table  t) ++ ", clusters=" ++ (show_clusters t) ++ "\n") all_tables
	appendFile res out

to_fann_input :: String -> IO String
to_fann_input file =
	do
		init <- initFile file
		let counts = if init then show trans_count ++ " " ++ show guard_count else ""
		let dna_t = get_table "dna"
		let dna_c = find_clusters dna_t
		let dnas@(dnax,dnay) = truesize "dna"
		let dna_o = (show $ true_frac dna_t) ++ " " ++ (show $ norm_ccount dna_c dnas) ++ " "  ++ (show $ ((fromIntegral $ sum $ map (\(_,c) -> length c) $ filter (not . fst) dna_c) / (fromIntegral $ length dna_c)) / (fromIntegral (dnax*dnay)))

		let nes_t = get_table "nes"
		let nes_c = find_clusters nes_t
		let ness@(nesx,nesy) = truesize "dna"
		let nes_o = (show $ true_frac nes_t) ++ " "  ++ (show $ norm_ccount nes_c ness) ++ " "  ++ (show $ ((fromIntegral $ sum $ map (\(_,c) -> length c) $ filter (not . fst) nes_c) / (fromIntegral $ length dna_c)) / (fromIntegral (nesx*nesy)))

		let nds_t = get_table "nds"
		let nds_c = find_clusters nds_t
		let ndss@(ndsx,ndsy) = truesize "dna"
		let nds_o = (show $ true_frac nds_t) ++ " "  ++ (show $ norm_ccount nds_c ndss) ++ " "  ++ (show $ ((fromIntegral $ sum $ map (\(_,c) -> length c) $ filter (not . fst) nds_c) / (fromIntegral $ length dna_c)) / (fromIntegral (ndsx*ndsy)))

		let coen_t = get_table "coen"
		let coen_c = find_clusters coen_t
		let coens@(coenx,coeny) = truesize "dna"
		let coen_o = (show $ true_frac coen_t) ++ " "  ++ (show $ norm_ccount coen_c coens) ++ " "  ++ (show $ ((fromIntegral $ sum $ map (\(_,c) -> length c) $ filter (not . fst) coen_c) / (fromIntegral $ length dna_c)) / (fromIntegral (coenx*coeny)))
		
		let result = counts ++ " " ++ dna_o ++ " " ++ nes_o ++ " " ++ nds_o ++ " " ++ coen_o ++ " " ++ (show c_glob_count)
		return result
	where
		norm_ccount c (x,y) = (fromIntegral $ length c) / (fromIntegral (x*y))

to_fann :: CString -> IO (Ptr Float)
to_fann file =
	do
		let init = from_c $ c_init file
		let all_tables | init == 0 =  ["dna", "nes", "nds", "coen"]
					     | otherwise = error "IO Error"
		let list = concat $ map to_fann_single all_tables
		arr <- newArray list
		return arr

to_fann_single :: String -> [Float]
to_fann_single tab = result
	where
		table = get_table tab
		frac = true_frac table
		(x, y) = truesize tab
		clusters = find_clusters table
		ccount = fromIntegral $ length clusters
		avgc = (fromIntegral $ sum $ map (\(_,c) -> length c) clusters) / ccount
		result =  [frac *  (fromIntegral (x*y)), ccount, avgc]

main = do
	args <- getArgs
	let files | length args /= 2 = error "Invalid input"
		          | otherwise = args
	to_csv (last files) (head files)
	--r <- to_fann_input $ head files
	--appendFile (last files) $ r++ "\n"
