module DataFlow.Core (
  ID,
  Value(..),
  Attributes,
  Diagram(..),
  RootNode(..),
  Flow(..),
  Node(..)
  ) where

import Data.Map as M

-- | An identifier corresponding to those in Graphviz.
type ID = String

data Value = String String
           | Array [Value]
           deriving (Eq)

instance Show Value where
  show (String s) = s
  show (Array vs) = show vs

-- | Attribute key-value pairs can be declared in diagrams, nodes, boundaries
-- | and flows.
type Attributes = M.Map String Value

-- | The top level diagram.
data Diagram = Diagram Attributes [RootNode] [Flow]
               deriving (Eq, Show)

-- | An root node in a diagram.
data RootNode =
              -- | A top level Node.
              Node Node
              -- | Surrounds other non-root nodes, denoting a boundary.
              | TrustBoundary ID Attributes [Node]
              deriving (Eq, Show)

data Node =
            -- | An /Input/ or /Output/ in DFD.
            InputOutput ID Attributes
            -- | A /Function/ in DFD.
            | Function ID Attributes
            -- | A /Database/ in DFD.
            | Database ID Attributes
            deriving (Show, Eq)

-- | Describes the flow of data between two nodes.
data Flow = Flow ID ID Attributes
            deriving (Show, Eq)
