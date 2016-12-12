module DataFlow.Attributes where

import qualified Data.Map as M
import Data.Functor ((<$>))

import DataFlow.Core

-- | Tries to find the title attribute, defaulting to a blank string.
getTitleOrBlank :: Attributes -> String
getTitleOrBlank = show . M.findWithDefault (String "") "title"

getHrefOrBlank :: Attributes -> String
getHrefOrBlank = show . M.findWithDefault (String "") "href"

-- | Tries to find the title attribute.
getTitle :: Attributes -> Maybe String
getTitle a = show <$> M.lookup "title" a

getHref :: Attributes -> Maybe String
getHref a = show <$> M.lookup "href" a
