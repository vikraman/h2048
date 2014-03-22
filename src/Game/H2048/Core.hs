module Game.H2048.Core
    ( Board
    , Line
    , Dir (..)
    , BoardUpdated (..)
    , GameState (..)
    , gameState
    , compactLine
    , initBoard
    , initGameBoard
    , updateBoard
    , insertNewCell
    , generateNewCell
    )
where

import Control.Arrow
import Control.Monad
import Control.Monad.Writer
import Control.Monad.Random
import Data.List
import Data.Maybe

import Game.H2048.Utils

-- | represent a 4x4 board for Game 2048
--   each element should be either zero or 2^i
--   where 1 <= i <= 11.
type Board = [[Int]]

-- | a list of 4 elements, stands for
--   one column / row in the board
type Line  =  [Int]

-- | result after a successful 'updateBoard'
data BoardUpdated = BoardUpdated
    { brBoard    :: Board  -- ^ new board
    , brScore    :: Int    -- ^ score collected in this update
    } deriving (Eq, Show)

-- | current game state
data GameState = Win
               | Lose
               | Alive
                 deriving (Enum, Eq, Show)

-- | the move direction
data Dir = DUp
         | DDown
         | DLeft
         | DRight
         deriving (Enum, Bounded, Eq, Ord, Show)

-- | the initial board before a game started
initBoard :: Board
initBoard = (replicate 4 . replicate 4) 0

-- | move each non-zero element to their leftmost possible
--   position while preserving the order
compactLine :: Line -> Writer (Sum Int) Line
compactLine = runKleisli
                    -- remove zeros
                  ( filter (/=0)
                    -- do merge and collect score
                ^>> Kleisli merge
                    -- restore zeros, on the "fst" part
                >>^ take 4 . (++ repeat 0))

    where
        merge :: [Int] -> Writer (Sum Int) [Int]
        merge (x:y:xs) =
            if x == y
                -- only place where score are collected.
                then do
                    -- try to merge first two elements,
                    -- and process rest of it.
                    xs' <- merge xs
                    tell . Sum $ x + y
                    return $ (x+y) : xs'
                else do
                    -- just skip the first one,
                    -- and process rest of it.
                    xs' <- merge (y:xs)
                    return $ x : xs'
        merge r = return r

-- | update the board taking a direction,
--   a "BoardUpdated" is returned on success,
--   if this update does nothing, that means a failure (Nothing)
updateBoard :: Dir -> Board -> Maybe BoardUpdated
updateBoard d board = if board /= board'
                          then Just $ BoardUpdated board' (getSum score)
                          else Nothing
    where
        board' :: Board
        -- transform boards so that
        -- we only focus on "gravitize to the left".
        -- and convert back after the gravitization is done.
        (board',score) = runWriter $
                         runKleisli
                               -- transform to a "gravitize to the left" problem
                             ( rTransL
                               -- gravitize to the left
                           ^>> Kleisli (mapM compactLine)
                               -- transform back
                           >>^ rTransR) board

        -- rTrans for "a list of reversible transformations, that will be performed in order"
        rTrans :: [Board -> Board]
        rTrans =
            case d of
              -- the problem itself is "gravitize to the left"
              DLeft  -> []
              -- we use a mirror
              DRight -> [map reverse]
              -- diagonal mirror
              DUp    -> [transpose]
              -- same as DUp case + DRight case
              DDown  -> [transpose, map reverse]

        -- how we convert it "into" and "back"
        rTransL = foldl (flip (.)) id rTrans
        rTransR = foldr       (.)  id rTrans

-- | find blank cells in a board,
--   return coordinates for each blank cell
blankCells :: Board -> [(Int, Int)]
blankCells b = map (\(row, (col, _)) -> (row,col)) blankCells'
    where
        blankCells' = filter ((== 0) . snd . snd) linearBoard
        -- flatten to make it ready for filter
        linearBoard = concat $ zipWith tagRow [0..] colTagged

        -- tag cells with row num
        tagRow row = map ( (,) row )
        -- tag cells with column num
        colTagged = map (zip [0..]) b

-- | return current game state.
--   "Win" if any cell is equal to or greater than 2048
--   or "Lose" if we can move no further
--   otherwise, "Alive"
gameState :: Board -> GameState
gameState b
    | any (>= 2048) . concat $ b
        = Win
    | all (isNothing . ( `updateBoard` b)) universe
        = Lose
    | otherwise
        = Alive

-- | initialize the board by puting two cells randomly
--   into the board.
--   See "generateNewCell" for the cell generating rule.
initGameBoard :: (MonadRandom r) => r (Board, Int)
initGameBoard =
    -- insert two cells and return the resulting board
    -- here we can safely assume that the board has at least two empty cells
    -- so that we can never have Nothing on the LHS
    liftM ( (\x -> (x,0)) . fromJust) (insertNewCell initBoard >>= (insertNewCell . fromJust))

-- | try to insert a new cell randomly
insertNewCell :: (MonadRandom r) => Board -> r (Maybe Board)
insertNewCell b = do
    -- get a list of coordinates of blank cells
    let availableCells = blankCells b

    if null availableCells
       -- cannot find any empty cell, then fail
       then return Nothing
       else do
           -- randomly pick up an available cell by choosing index
           choice <- getRandomR (0, length availableCells - 1)
           let (row,col) = availableCells !! choice
           value <- generateNewCell
           return $ Just $ (inPos row . inPos col) (const value) b

-- | generate a new cell according to the game rule
--   we have 90% probability of getting a cell of value 2,
--   and 10% probability of getting a cell of value 4.
generateNewCell :: (MonadRandom r) => r Int
generateNewCell = do
    r <- getRandom
    return $ if r < (0.9 :: Float) then 2 else 4
