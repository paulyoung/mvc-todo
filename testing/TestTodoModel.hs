{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module TestTodoModel where

import Todo.Model

import           Control.Applicative
import           Control.Monad
import           Test.Tasty.Hspec
import Data.Monoid
import Data.Default (def)
import Test.QuickCheck
import qualified Data.Map as Map
import Data.String

demoActions :: [Action String]
demoActions = 
  mconcat ((\x -> [ NewItem ("item number " ++ show x)]) <$> [0..5]) ++
  (Toggle . ItemId <$> [0,2,4]) ++
  [ToggleAll] ++
  [ClearCompleted] ++
  (DeleteItem . ItemId <$> [0]) ++
  mconcat ((\x -> [ EditItem (ItemId x), EditItemDone (ItemId x) ("item done: " ++ show x), Toggle (ItemId x)]) <$> [2])

demoTodos :: Todos String
demoTodos = foldl (flip apply) def demoActions

demoAfterActions :: Todos String
demoAfterActions =
  Todos "" Nothing (ItemId 6) Nothing
  ( Map.fromList
    [ (ItemId 2, Item { _itemStatus = Completed , _itemText = "item done: 2" })
    , (ItemId 4, Item { _itemStatus = Active    , _itemText = "item number 4" })
    ]
  )

tests :: IO (SpecWith())
tests =
  return $ describe "initial r&d" $
    it "canned demo ok"     $ 
      demoTodos `shouldBe` demoAfterActions

instance Arbitrary ItemStatus where
  arbitrary = 
    elements 
    [ Active
    , Completed
    ]

instance Arbitrary ItemId where
  arbitrary = do
    let maxI = 10
    ItemId <$> choose (0,maxI)

instance Arbitrary (Item String) where
  arbitrary = Item <$> arbitrary <*> (show <$> (arbitrary :: Gen TodoStatement))

instance Arbitrary (Todos String) where
  arbitrary = 
    Todos <$> 
    (show <$> (arbitrary :: Gen HaskellVerb)) <*> 
    frequency
    [ (8, pure Nothing)
    , (2, Just <$> arbitrary)
    ] <*>
    arbitrary <*>
    frequency
    [ (6, pure Nothing)
    , (4, Just <$> arbitrary)
    ] <*>
    (Map.fromList <$> (\x -> [x]) <$> ((,) <$> arbitrary <*> arbitrary))

instance Arbitrary (Action String) where
  arbitrary = frequency
    [ (10, Toggle <$> arbitrary)
    , (2,  pure ToggleAll)
    , (6,  NewItem <$> (show <$> (arbitrary :: Gen TodoStatement)))
    , (6,  EditItem <$> arbitrary)
    , (6,  EditItemCancel <$> arbitrary)
    , (6,  EditItemDone <$> arbitrary <*> (show <$> (arbitrary :: Gen TodoStatement)))
    , (2,  Filter <$> arbitrary)
    , (4,  DeleteItem <$> arbitrary)
    , (1,  pure ClearCompleted)
    ]

testApply :: IO [Todos String]
testApply = 
  Prelude.zipWith apply <$> 
  sample' arbitrary <*> 
  sample' arbitrary

data TodoStatement = TodoStatement HaskellVerb HaskellNoun

instance Show TodoStatement where
  show (TodoStatement verb noun) = show verb <> " " <> show noun

newtype HaskellVerb = HaskellVerb { unVerb :: String }

instance IsString HaskellVerb where
  fromString s = HaskellVerb s

instance Show HaskellVerb where
  show (HaskellVerb s) = s

newtype HaskellPrefix = HaskellPrefix { unPrefix :: String } deriving (Show)
newtype Haskellism    = Haskellism    { unHaskellism :: String } deriving (Show)
newtype HaskellSuffix = HaskellSuffix { unSuffix :: String } deriving (Show)

data HaskellNoun = HaskellNoun [HaskellPrefix] Haskellism [HaskellSuffix]

instance Show HaskellNoun where
  show (HaskellNoun ps h ss) = mconcat (unPrefix <$> ps) <> unHaskellism h <> (mconcat $ unSuffix <$> ss)

instance Arbitrary (TodoStatement) where
  arbitrary = TodoStatement <$> arbitrary <*> arbitrary

instance Arbitrary (HaskellNoun) where
  arbitrary = HaskellNoun <$> arbitrary <*> arbitrary <*> arbitrary

instance Arbitrary (HaskellVerb) where
  arbitrary = frequency $ (\(x,y) -> (x, pure y)) <$>
    [ (9, "invent")
    , (5, "ponder")
    , (3, "code")
    ]
instance Arbitrary (HaskellPrefix) where
  arbitrary = frequency $ (\(x,y) -> (x, pure (HaskellPrefix y))) <$>
    [ (9, "homo")
    , (5, "functo")
    , (3, "morph")
    ]

instance Arbitrary (HaskellSuffix) where
  arbitrary = frequency $ (\(x,y) -> (x, pure (HaskellSuffix y))) <$>
    [ (9, "ism")
    , (5, "orial")
    , (3, "al")
    ]

instance Arbitrary (Haskellism) where
  arbitrary = frequency $ (\(x,y) -> (x, pure (Haskellism y))) <$>
    [ (9, "functor")
    , (5, "monoid")
    , (3, "applicative")
    , (4, "arrow")
    ]







