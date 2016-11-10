{-# LANGUAGE DeriveGeneric #-}
module BulkClauseImport where

import           Control.Applicative    (pure, (*>), (<$>), (<*>), (<|>))
import qualified Control.Arrow
import           Data.Aeson             (ToJSON (..))
import qualified Data.Aeson             as Aeson
import           Data.Aeson.Types       (Options (fieldLabelModifier), camelTo2)
import           Data.Either            (Either (..))
import           Data.List              (stripPrefix)
import           Data.Maybe             (fromMaybe)
import           GHC.Generics           (Generic)
import           Prelude                (Eq, Show, String, show, ($), (.))
import           Text.Megaparsec
import           Text.Megaparsec.String


data ClauseType
  = Whereas
  | BeItResolved
  | BeItFurtherResolved
  deriving (Eq, Generic, Show)


instance ToJSON ClauseType


data Clause = Clause
  { clauseType :: ClauseType
  , clauseContent :: String
  } deriving (Eq, Generic, Show)


instance ToJSON Clause where
  toEncoding =
    Aeson.genericToEncoding $
      Aeson.defaultOptions {
        fieldLabelModifier = \key -> camelTo2 '_' $ fromMaybe key $ stripPrefix "clause" key
      }


clauseParser :: Parser Clause
clauseParser = Clause
  <$> clauseTypeParser
  <*> (space *> string "," *> space *> someTill anyChar (lookAhead clauseEndParser))


clauseTypeParser :: Parser ClauseType
clauseTypeParser = choice
  [ string' "whereas" *> pure Whereas
  , string' "be it resolved" *> pure BeItResolved
  , string' "be it further resolved" *> pure BeItFurtherResolved
  ]


clauseEndParser :: Parser ()
clauseEndParser = try (clauseJoinPhraseParser *> nlOrEof) <|> nlOrEof
  where
    nlOrEof = skipSome newline <|> eof


clauseJoinPhraseParser :: Parser ()
clauseJoinPhraseParser = char ';' *> space *> phraseParser *> optional (try $ space *> char ',') *> pure ()
  where
    phraseParser = choice
      [ string' "and"
      , string' "now" *> space *> char ',' *> space *> string' "therefore"
      ]

clausesParser :: Parser [Clause]
clausesParser = sepEndBy clauseParser clauseEndParser


parseClauses :: String -> Either String [Clause]
parseClauses = Control.Arrow.left show . parse clausesParser ""
