{-# LANGUAGE OverloadedStrings #-}
module DataFlow.JSONGraphFormat (
  Val(..),
  Metadata(),
  Document(..),
  Graph(..),
  Node(..),
  Edge(..)
  ) where

import           Data.Aeson
import           Data.Aeson.Types (Pair)
import qualified Data.Map         as M
import           Data.Vector      (fromList)

data Val = Str String
         | Arr [Val]

instance ToJSON Val where
  toJSON (Str s) = toJSON s
  toJSON (Arr vs) = toJSON vs

type Metadata = M.Map String Val

data Document = SingleGraph { graph :: Graph }
              | MultiGraph { graphs :: [Graph] }

instance ToJSON Document where
  toJSON (SingleGraph g) = object [
      "graph" .= toJSON g
    ]
  toJSON (MultiGraph gs) = object [
      "graphs" .= toJSON gs
    ]

data Graph = Graph { nodes    :: [Node]
                   , edges    :: [Edge]
                   , graphLabel    :: Maybe String
                   , graphMetadata :: Metadata
                   }

instance ToJSON Graph where
  toJSON (Graph nodes edges lbl metadata) = object $
    labelField lbl ++ [
      "nodes" .= toJSON nodes,
      "edges" .= toJSON edges,
      "metadata" .= toJSON metadata
    ]

data Node = Node { id :: String
                 , nodeLabel :: Maybe String
                 , nodeMetadata :: Metadata }

instance ToJSON Node where
  toJSON (Node id' lbl metadata) = object $
    labelField lbl ++ [
      "id" .= toJSON id',
      "metadata" .= toJSON metadata
    ]

data Edge = Edge { source :: String
                 , target :: String
                 , edgeLabel :: Maybe String
                 , edgeMetadata :: Metadata }

instance ToJSON Edge where
  toJSON (Edge source target lbl metadata) = object $
    labelField lbl ++ [
      "source" .= toJSON source,
      "target" .= toJSON target,
      "metadata" .= toJSON metadata
    ]

labelField :: Maybe String -> [Pair]
labelField (Just s) = [("label", toJSON s)]
labelField _ = []
