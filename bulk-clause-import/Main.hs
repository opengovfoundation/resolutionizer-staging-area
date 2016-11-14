module Main where

import qualified BulkClauseImport
import qualified Data.Aeson           as Aeson
import qualified Data.ByteString.Lazy as ByteString
import           Data.Either          (Either (..))
import qualified Data.Either
import qualified Data.List
import           Prelude              (IO, (.), ($))
import qualified System.Environment
import qualified System.Exit
import qualified System.IO

main :: IO ()
main = do
  args <- System.Environment.getArgs
  input <- case args of
    [] -> System.IO.getContents
    file : _ -> System.IO.readFile file

  -- case BulkClauseImport.parseClauses input of
  --   Right clauseData -> do
  --     ByteString.putStr (Aeson.encode clauseData)
  --     System.Exit.exitSuccess
  --   Left errMsg -> do
  --     System.IO.putStr errMsg
  --     System.Exit.exitFailure

  let parseResult = BulkClauseImport.parseClausesPerClause input
  case Data.Either.partitionEithers parseResult of
    ([], clauses) ->
      ByteString.putStr $ Aeson.encode clauses

    (errMsgs, _) -> do
      System.IO.putStr (Data.List.unlines errMsgs)
      System.Exit.exitFailure
