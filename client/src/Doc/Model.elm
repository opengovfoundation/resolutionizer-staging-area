module Doc.Model exposing (Model, Clause, ClauseInfo, ClauseType, emptyDoc, newClause, newSponsor)

import Array exposing (Array)
import Dict exposing (Dict)


type alias Model =
    { title : String
    , sponsors : Dict Int Sponsor
    , clauses : Dict Int Clause
    , validSponsors : List String
    , validClauseTypes : ClauseInfo
    , defaultClauseType : ClauseType
    }


type alias Sponsor =
    { name : String
    , pos : Int
    }


type alias Clause =
    { ctype : ClauseType
    , content : String
    , id : Int
    , pos : Int
    }


type alias ClauseInfo =
    Dict ClauseType ClauseTypeDesc


type alias ClauseType =
    String


type alias ClauseTypeDesc =
    { displayName : String
    }


emptyDoc : Model
emptyDoc =
    { title = ""
    , sponsors = Dict.empty
    , clauses = Dict.empty
    , validSponsors = chicagoSponsors
    , validClauseTypes =
        Dict.fromList
            [ ( "Whereas", { displayName = "WHEREAS" } )
            , ( "BeItResolved", { displayName = "BE IT RESOLVED" } )
            , ( "BeItFurtherResolved", { displayName = "BE IT FURTHER RESOLVED" } )
            ]
    , defaultClauseType = "Whereas"
    }


newClause : Int -> Int -> ClauseType -> String -> Clause
newClause id pos ctype content =
    { ctype = ctype
    , content = content
    , id = id
    , pos = pos
    }


newSponsor : Int -> String -> Sponsor
newSponsor pos name =
    { name = name
    , pos = pos
    }


chicagoSponsors : List String
chicagoSponsors =
    [ "Arena, John (45)"
    , "Austin, Carrie M. (34)"
    , "Beale, Anthony (9)"
    , "Brookins, Jr., Howard (21)"
    , "Burke, Edward M. (14)"
    , "Burnett, Jr., Walter (27)"
    , "Cappleman, James (46)"
    , "Cardenas, George A. (12)"
    , "Cochran, Willie (20)"
    , "Curtis, Derrick G. (18)"
    , "Dowell, Pat (3)"
    , "Emanuel, Rahm (Mayor)"
    , "Ervin, Jason C. (28)"
    , "Foulkes, Toni (16)"
    , "Hairston, Leslie A. (5)"
    , "Harris, Michelle A. (8)"
    , "Hopkins, Brian (2)"
    , "King, Sophia (4)"
    , "Laurino, Margaret (39)"
    , "Lopez, Raymond A. (15)"
    , "Maldonado, Roberto (26)"
    , "Mell, Deborah (33)"
    , "Mendoza, Susana A. (Clerk)"
    , "Mitchell, Gregory I. (7)"
    , "Mitts, Emma (37)"
    , "Moore, David H. (17)"
    , "Moore, Joseph (49)"
    , "Moreno, Proco Joe (1)"
    , "Munoz, Ricardo (22)"
    , "Napolitano, Anthony V. (41)"
    , "O'Connor, Patrick (40)"
    , "O'Shea, Matthew J. (19)"
    , "Osterman, Harry (48)"
    , "Pawar, Ameya (47)"
    , "Quinn, Marty (13)"
    , "Ramirez-Rosa, Carlos (35)"
    , "Reboyras, Ariel (30)"
    , "Reilly, Brendan (42)"
    , "Sadlowski Garza, Susan (10)"
    , "Santiago, Milagros S. (31)"
    , "Sawyer, Roderick T. (6)"
    , "Scott, Jr. Michael (24)"
    , "Silverstein, Debra L. (50)"
    , "Smith, Michele (43)"
    , "Solis, Daniel (25)"
    , "Sposato, Nicholas (38)"
    , "Taliaferro, Chris (29)"
    , "Thompson, Patrick D. (11)"
    , "Tunney, Thomas (44)"
    , "Villegas, Gilbert (36)"
    , "Waguespack, Scott (32)"
    , "Zalewski, Michael R. (23)"
    ]
