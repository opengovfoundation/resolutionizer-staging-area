module Main where

import qualified BulkClauseImport
import qualified Data.Aeson           as Aeson
import qualified Data.ByteString.Lazy as ByteString
import           Data.Either          (either)
import           Prelude              (IO, (.))
import qualified System.IO

main :: IO ()
main = do
  input <- System.IO.getContents
  let parseResult = BulkClauseImport.parseClauses input
  either (System.IO.putStr) (ByteString.putStr . Aeson.encode) parseResult
