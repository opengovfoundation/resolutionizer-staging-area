module Doc.Fixtures exposing (..)

import Dict
import Doc


emptyDoc : Doc.Model
emptyDoc =
    { title = ""
    , meetingDate = Nothing
    , sponsors = Dict.empty
    , clauses = Dict.empty
    , validSponsors = validSponsors
    , validClauseTypes = clauseTypes
    , defaultClauseType = "Middle"
    }


clauseTypes : Doc.ClauseInfo
clauseTypes =
    Dict.fromList
        [ ( "Beginning", { displayName = "The Beginning", sortWeight = 1 } )
        , ( "Middle", { displayName = "The Middle", sortWeight = 2 } )
        , ( "End", { displayName = "Then End", sortWeight = 3 } )
        ]


validSponsors : List String
validSponsors =
    [ "Arena, John (45)"
    , "Austin, Carrie M. (34)"
    , "Beale, Anthony (9)"
    ]
