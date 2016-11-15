module BulkClauseImportSpec (main, spec) where

import           BulkClauseImport
import           Data.Foldable         (forM_)
import           Data.List             ((++))
import           Prelude               (IO, ($))
import           Test.Hspec
import           Test.Hspec.Megaparsec
import           Text.Megaparsec       (parse)

-- `main` is here so that this module can be run from GHCi on its own.  It is
-- not needed for automatic spec discovery.
main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "clauseParser" $ do
    it "handles uppercase clause types" $
      parse clauseParser "" "WHEREAS, This is some content." `shouldParse` Clause { clauseType = Whereas, clauseContent = "This is some content." }

    it "handles capital case clause types" $
      parse clauseParser "" "Whereas, This is some content." `shouldParse` Clause { clauseType = Whereas, clauseContent = "This is some content." }

    it "handles lowercase clause types" $
      parse clauseParser "" "whereas, This is some content." `shouldParse` Clause { clauseType = Whereas, clauseContent = "This is some content." }

    it "fails on invalid clause types" $
      parse clauseParser "" `shouldFailOn` "WHATIS, This is some bad content"

    it "skips trailing clause join phrases, if present" $
      parse clauseParser "" "WHEREAS, This is some content; and" `shouldParse` Clause { clauseType = Whereas, clauseContent = "This is some content" }

    it "includes non-trailing join phrases, if present" $
      parse clauseParser "" "WHEREAS, This is; and some content; and" `shouldParse` Clause { clauseType = Whereas, clauseContent = "This is; and some content" }

    it "skips trailing spaces after clause join phrases, if present" $
      parse clauseParser "" "WHEREAS, This is some content; and " `shouldParse` Clause { clauseType = Whereas, clauseContent = "This is some content" }

    it "skips trailing spaces, if present" $
      parse clauseParser "" "WHEREAS, This is some content " `shouldParse` Clause { clauseType = Whereas, clauseContent = "This is some content" }


  describe "clausesParser" $ do
    it "handles two clause types" $ do
      let input = "WHEREAS, This is some content.\nBe it resolved, This is more content."
          output =
            [ Clause { clauseType = Whereas, clauseContent = "This is some content." }
            , Clause { clauseType = BeItResolved, clauseContent = "This is more content." }
            ]
      parse clausesParser "" input `shouldParse` output

    it "handles multiple newlines between clauses" $ do
      let input = "WHEREAS, This is some content.\n\nBe it resolved, This is more content."
          output =
            [ Clause { clauseType = Whereas, clauseContent = "This is some content." }
            , Clause { clauseType = BeItResolved, clauseContent = "This is more content." }
            ]
      parse clausesParser "" input `shouldParse` output

    it "handles clause join phrases" $ do
      let input = "WHEREAS, This is some content; and\nWhereas, Some more stuff; Now, therefore\nBe it resolved, This is more content."
          output =
            [ Clause { clauseType = Whereas, clauseContent = "This is some content" }
            , Clause { clauseType = Whereas, clauseContent = "Some more stuff" }
            , Clause { clauseType = BeItResolved, clauseContent = "This is more content." }
            ]
      parse clausesParser "" input `shouldParse` output

    it "handles clause join phrases with trailing commas" $ do
      let input = "WHEREAS, This is some content; and,\nWhereas, Some more stuff; Now, therefore,\nBe it resolved, This is more content."
          output =
            [ Clause { clauseType = Whereas, clauseContent = "This is some content" }
            , Clause { clauseType = Whereas, clauseContent = "Some more stuff" }
            , Clause { clauseType = BeItResolved, clauseContent = "This is more content." }
            ]
      parse clausesParser "" input `shouldParse` output

    it "handles clause join phrases with trailing spaces" $ do
      let input = "WHEREAS, This is some content; and \nWhereas, Some more stuff; Now, therefore  \nBe it resolved, This is more content."
          output =
            [ Clause { clauseType = Whereas, clauseContent = "This is some content" }
            , Clause { clauseType = Whereas, clauseContent = "Some more stuff" }
            , Clause { clauseType = BeItResolved, clauseContent = "This is more content." }
            ]
      parse clausesParser "" input `shouldParse` output


  describe "clauseJoinPhraseParser" $
    forM_
      [ "; and"
      , "; now, therefore"
      , "; Now, therefore"
      , ";     now,     therefore"
      , "; now, therefore,"
      , "; now, therefore, "
      ]
      (\phrase ->
          it ("handles '" ++ phrase ++ "'") $
            parse clauseJoinPhraseParser "" phrase `shouldParse` ()
      )
